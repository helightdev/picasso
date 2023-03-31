import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:picasso/picasso.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' as ui;

import 'brightness.dart';
import 'temperature.dart';

late ui.Image backgroundImage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  backgroundImage =
      await loadImageFromProvider(const AssetImage("assets/background.jpg"));
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.from(
              colorScheme: const ColorScheme.dark(primary: Colors.yellow))
          .copyWith(textTheme: GoogleFonts.poppinsTextTheme()),
      home: const MainView(),
      locale: const Locale("de"),
      supportedLocales: const [Locale("de"), Locale("en"), Locale("es")],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        PicassoTranslations.delegate
      ],
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  GlobalKey<PicassoEditorState> picassoKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: mq.size.width,
        height: mq.size.height,
        child: PicassoEditor(
            settings: CanvasSettings(height: 1080, width: 1080),
            containerFactory: const ModernColumnEditorContainerFactory(),
            dialogFactory: const BottomSheetEditorDialogFactory(),
            displayWidgetFactory:
                const ModernToolDisplayWidgetFactory(increasedSize: true),
            bottomWidgetFactory: ElevatedButtonBottomWidgetFactory.$continue(),
            bindings: {
              FilterDataProvider.key: FilterDataProvider(
                presets: {
                  "sun-kissed": FilterPreset.linearGradient("Sun Kissed",
                      colors: [const Color(0xFFffed00), const Color(0xFFe5007d)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  "campus-life": FilterPreset.linearGradient("Campus Life",
                      colors: [
                        const Color(0xFFe5007d),
                        const Color(0xFF009ee3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  "sunny-beach": FilterPreset.linearGradient("Sunny Beach",
                      colors: [const Color(0xFF009ee3), const Color(0xFFffed00)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight),
                  "cl": FilterPreset.tone("Christian Lindner", Colors.black,
                      blendMode: BlendMode.saturation,
                      preview: Image.asset(
                        "assets/lindner.jpg",
                        fit: BoxFit.cover,
                      )),
                }
              ),
              StencilDataProvider.key: const StencilDataProvider(
                presets: {
                  "vignette": StencilPreset("Vignette", AssetImage("assets/vignette.png")),
                  "classic": StencilPreset("Classic", NetworkImage(
                          "https://cdn.pixabay.com/photo/2017/07/09/10/11/frame-2486548_960_720.png")),
                  "sovereign": StencilPreset("Sovereign", NetworkImage(
                          "https://www.pngplay.com/wp-content/uploads/12/Photo-Frame-Transparent-Free-PNG-Clip-Art.png")),
                }
              )
            },
            tools: [
              ImageTool(SizedImage(AssetImage("assets/background.jpg"), Size(3540, 2832))),
              //GifTool(NetworkImage("https://i0.wp.com/www.printmag.com/wp-content/uploads/2021/02/4cbe8d_f1ed2800a49649848102c68fc5a66e53mv2.gif?fit=476%2C280&ssl=1")),
              LayersTool(),
              PreviewTool(),
              ReloadTool(),
              TextTool(
                  style: GoogleFonts.oswald(
                      textStyle: const TextStyle(
                          color: Colors.red,
                          shadows: TextToolUtils.impactOutline),
                      fontWeight: FontWeight.bold)),
              const FilterTool(),
              const StencilTool(),
              const StickerTool(presets: [
                SizedImage(AssetImage("assets/dash.png"), Size(860, 860)),
                SizedImage(
                    NetworkImage(
                        "https://cdn.icon-icons.com/icons2/2699/PNG/512/minecraft_logo_icon_168974.png"),
                    Size(64, 64))
              ]),
              ExportTool(),
            ],
            key: picassoKey),
      ),
    );
  }
}
