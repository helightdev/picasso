import 'dart:developer';
import 'dart:ui';

import 'package:duffer/duffer.dart';
import 'package:logging/logging.dart';
import 'package:picasso/picasso.dart';

class PicassoSaveSystem {
  List<PicassoLayerSerializer> serializers;

  final Logger _logger = Logger("PicassoSaveSystem");
  
  PicassoSaveSystem(this.serializers);

  static PicassoSaveSystem instance = PicassoSaveSystem([
    FilterLayerSerializer(),
    StencilLayerSerializer(),
    TextLayerSerializer(),
    StickerLayerSerializer(),
    RawImageLayerSerializer(),
    ImageLayerSerializer(),
    GifLayerSerializer()
  ]);

  static void registerSerializer(PicassoLayerSerializer serializer) {
    instance.serializers.add(serializer);
  }

  Future<ByteBuf> save(PicassoCanvasState state) async {
    state.showLoading();
    var buf = Unpooled.buffer();
    buf.writeSize(Size(
        state.widget.settings.width,
        state.widget.settings.height
    ));
    var ratio = state.widget.settings.width / state.canvasSize.width;
    var transfer = <_LayerSaveTransferData>[];
    for (var i = 0; i < state.layerCount; i++) {
      var layer = state.layers[i];
      var transform = state.transforms[i];
      var matching = serializers.where((element) => element.check(layer));
      if (matching.isEmpty) {
        continue;
      }
      var serializer = matching.first;
      transfer.add(_LayerSaveTransferData(layer, transform, serializer));
    }
    buf.writeInt64(transfer.length);
    _logger.fine("Saving ${transfer.length} layers");
    for (var entry in transfer) {
      _logger.fine("Writing layer ${entry.layer.id} using serializer ${entry.serializer.serialName}");
      var before = buf.writerIndex;
      buf.writeLPString(entry.layer.id);
      buf.writeLPString(entry.serializer.serialName);
      buf.writeLPString(entry.layer.name);
      buf.writeTransformData(entry.transform.rescale(ratio));
      buf.writeBool(entry.layer.hidden);
      buf.writeBool(entry.layer.locked);
      await entry.serializer.serialize(entry.layer, buf, state);
      var after = buf.writerIndex;
      _logger.fine("Wrote ${((after-before).toDouble() / 1000.0).toStringAsFixed(2)}kB to output buffer");
    }
    _logger.fine("Final output buffer size is ${(buf.readableBytes.toDouble() / 1000.0).toStringAsFixed(2)}kB");
    state.hideLoading();
    return buf;
  }

  CanvasSaveData load(ByteBuf buf) {
    var size = buf.readSize();
    return CanvasSaveData(size, (state,editorState,callback) async {
      buf.markReaderIndex();
      var ratio = state.canvasSize.width / size.width;
      var layerCount = buf.readInt64();
      for (var i = 0; i < layerCount; i++) {
        var id = buf.readLPString();
        var serialName = buf.readLPString();
        var name = buf.readLPString();
        var serializer = serializers
            .firstWhere((element) => element.serialName == serialName);
        var transform = buf.readTransformData().rescale(ratio);
        var hidden = buf.readBool();
        var locked = buf.readBool();
        var layer = await serializer.deserialize(buf, state, editorState);
        layer.id = id;
        layer.name = name;
        layer.hidden = hidden;
        layer.locked = locked;
        state.addLayer(layer, transform);
      }
      buf.resetReaderIndex();
      callback?.call();
    });
  }
}

class _LayerSaveTransferData {

  PicassoLayer layer;
  TransformData transform;
  PicassoLayerSerializer serializer;

  _LayerSaveTransferData(this.layer, this.transform, this.serializer);


}

class CanvasSaveData {
  Size targetSize;
  Function(PicassoCanvasState, PicassoEditorState?, Function()?) initializer;

  CanvasSaveData(this.targetSize, this.initializer);
  
  dynamic initializeCanvas(PicassoCanvasState state, [VoidCallback? callback]) => initializer(state, null, callback);
  dynamic initializeEditor(PicassoEditorState state, [VoidCallback? callback]) => initializer(state.canvas, state, callback);
  
}
