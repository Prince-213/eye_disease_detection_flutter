import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image/image.dart' as img;

import 'package:tflite_v2/tflite_v2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:velocity_x/velocity_x.dart';

final busyProvider = StateNotifierProvider<BusyNotifier, bool>((ref) {
  return BusyNotifier();
});

class BusyNotifier extends StateNotifier<bool> {
  BusyNotifier(): super(false);

  void change ( bool value ) {
    state = value;
  }

}

final imagePathProvider = StateNotifierProvider<ImagePathNotifier, String>((ref) {
  return ImagePathNotifier();
});

class ImagePathNotifier extends StateNotifier<String> {
  ImagePathNotifier(): super('');

  void setPath ( String value ) {
    state = value;
  }

}


final startPredictionProvider = StateNotifierProvider.autoDispose<StartPredictionNotifier, List<dynamic>>((ref) {
  return StartPredictionNotifier();
});

class StartPredictionNotifier extends StateNotifier<List<dynamic>> {
StartPredictionNotifier(): super([0, 'label']);


Future prediction ( String path ) async {

  state = [0, 'analyzing....'];
  var recognitions = await Tflite.runModelOnImage(
      path: path,   // required
      imageMean: 0.0,   // defaults to 117.0
      imageStd: 255.0,  // defaults to 1.0
      numResults: 2,    // defaults to 5
      threshold: 0.2,   // defaults to 0.1
      asynch: true      // defaults to true
  );

  if (recognitions != null) {
    state = [];
    state.add(recognitions.first['confidence']);
    state.add(recognitions.first['label']);

    print(recognitions);
  }


  print(state);
}

}


class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {


  @override
  void initState() {
    super.initState();
    // ref.read(busyProvider.notifier).change(true);

    loadModel().then((val) {
      // ref.read(busyProvider.notifier).change(false);
    });
  }

  @override
  void dispose(){
    Tflite.close();
    super.dispose();
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);


    if (image != null ) {
      String path = image.path;
      ref.read(imagePathProvider.notifier).setPath(path);

      ref.read(startPredictionProvider.notifier).prediction(ref.watch(imagePathProvider));
    }
  }

  Future snapImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);


    if (image != null ) {
      String path = image.path;
      ref.read(imagePathProvider.notifier).setPath(path);

      ref.read(startPredictionProvider.notifier).prediction(ref.watch(imagePathProvider));
    }
  }

  Future loadModel() async {

    String? res = await Tflite.loadModel(model: 'assets/model_unquant.tflite', labels: 'assets/labels.txt', numThreads: 1, // defaults to 1
        isAsset: true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate: false // defaults to false, set to true to use GPU delegate
    );
    print('responded');
    print(res);
  }

  @override
  Widget build(BuildContext context) {

    String imagePath = ref.watch(imagePathProvider);



      dynamic confidence = ref.watch(startPredictionProvider)[0];
      dynamic label =  ref.watch(startPredictionProvider)[1];



    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text('Mobile HealthCare Labelling System', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
        centerTitle: true,
      ),
      body: Center(

        child: VStack(
          [
            VxBox(child: VStack([

              imagePath == '' ? VxBox(
                  child: Center(
                    child: Icon(Icons.image_rounded, size: 150,),
                  )
              ).color(Vx.white.withOpacity(.8)).height(200).roundedLg.make(): VxBox(
                  
              ).color(Vx.white.withOpacity(.8)).height(200).bgImage(DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)).roundedLg.make(),


              Spacer(),
              Text(label.toString()).text.xl.bold.capitalize.make().objectCenter(),
              Spacer(),
              // Text('Accuracy: ${(confidence * 100).toStringAsFixed(2)}%').text.bold.xl.make().objectCenter()
            ], alignment: MainAxisAlignment.center,)).width(context.percentWidth * 70).p24.color(Colors.deepOrangeAccent.shade100).height(320).outerShadow2Xl.roundedLg.make(),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: (){
              pickImage();
            }, child: HStack([
              Icon(Icons.image_outlined),
              Text('From Gallery').text.semiBold.lg.make().objectCenter(),

            ])),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: (){
              snapImage();
            }, child: HStack([
              Icon(Icons.camera_outlined),
              Text('From Camera').text.semiBold.lg.make().objectCenter(),
            ])),
          ], alignment: MainAxisAlignment.center,
          crossAlignment: CrossAxisAlignment.center,
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}