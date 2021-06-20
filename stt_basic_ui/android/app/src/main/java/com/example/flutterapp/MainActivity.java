package com.example.flutterapp;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
//import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.example.sttbasicui.R;
import com.google.api.gax.core.CredentialsProvider;
import com.google.api.gax.core.FixedCredentialsProvider;
import com.google.api.gax.longrunning.OperationFuture;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.cloud.speech.v1.LongRunningRecognizeMetadata;
import com.google.cloud.speech.v1.LongRunningRecognizeResponse;
import com.google.cloud.speech.v1.RecognitionAudio;
import com.google.cloud.speech.v1.RecognitionConfig;
import com.google.cloud.speech.v1.RecognitionConfig.AudioEncoding;
import com.google.cloud.speech.v1.RecognizeResponse;
import com.google.cloud.speech.v1.SpeechClient;
import com.google.cloud.speech.v1.SpeechRecognitionAlternative;
import com.google.cloud.speech.v1.SpeechRecognitionResult;
import com.google.cloud.speech.v1.SpeechSettings;

import com.google.protobuf.ByteString;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import androidx.annotation.NonNull;

import javax.xml.transform.Result;

import io.flutter.embedding.engine.FlutterEngine;

import io.flutter.plugins.GeneratedPluginRegistrant;




public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.example.sttbasicui";
    String speechresult = "";

    public MainActivity() throws IOException {
    }
    private static final int REQUEST_EXTERNAL_STORAGE = 1;
    private static String[] PERMISSIONS_STORAGE = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
    };

    /**
     * Checks if the app has permission to write to device storage
     *
     * If the app does not has permission then the user will be prompted to grant permissions
     *
     * @param activity
     */
    public static void verifyStoragePermissions(Activity activity) {
        // Check if we have write permission
        int permission = ActivityCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE);

        if (permission != PackageManager.PERMISSION_GRANTED) {
            // We don't have permission so Prompt the user
            ActivityCompat.requestPermissions(
                    activity,
                    PERMISSIONS_STORAGE,
                    REQUEST_EXTERNAL_STORAGE
            );
        }
    }
    @RequiresApi(api = Build.VERSION_CODES.O)
    public void asyncRecognizeFile(String fileName) throws Exception {
        try  {
            System.out.println("auth start");
            InputStream inputStream = getResources().openRawResource(R.raw.credential);//Input Stream을 통해 API 사용 권한을 위한 Credential.json 파일을 가져온다
            CredentialsProvider credentialsProvider = FixedCredentialsProvider.create(ServiceAccountCredentials.fromStream(inputStream));//credentialporvider에 Credential 파일을 넣는다
            SpeechSettings settings = SpeechSettings.newBuilder().setCredentialsProvider(credentialsProvider).build();//Client 생성을 위한 설정
            SpeechClient speech = SpeechClient.create(settings);//Client 생성
            System.out.println("auth complete");

            Path path = Paths.get(fileName);//STT할 오디오 파일 경로를 가져온다
            byte[] data = Files.readAllBytes(path);// 오디오 파일을 byte로 읽어온다
            ByteString audioBytes = ByteString.copyFrom(data);

            // Encoding 설정, 언어 설정, 샘플링 주파수 설정을 Build 한후 config에 넣어준다.
            RecognitionConfig config =
                    RecognitionConfig.newBuilder()
                            .setEncoding(AudioEncoding.LINEAR16)
                            .setLanguageCode("ko_KR")
                            .setSampleRateHertz(16000)
                            .build();
            System.out.println("설정 성공");
            //audio 변수에 STT하고자하는 byte로 읽어들인 파일을 넣는다
            RecognitionAudio audio = RecognitionAudio.newBuilder().setContent(audioBytes).build();
            OperationFuture<LongRunningRecognizeResponse, LongRunningRecognizeMetadata> response =
                    speech.longRunningRecognizeAsync(config, audio);

            while (!response.isDone()) {
                System.out.println("Waiting for response...");
                Thread.sleep(10000);
            }
            // 1분 이상의 긴 오디오 파일을 STT할때 쓰는
            //RecognizeResponse response = speech.recognize(config, audio);
            List<SpeechRecognitionResult> results = response.get().getResultsList();

            for (SpeechRecognitionResult result : results) {
                // There can be several alternative transcripts for a given chunk of speech. Just use the
                // first (most likely) one here.
                SpeechRecognitionAlternative alternative = result.getAlternativesList().get(0);
                speechresult = alternative.getTranscript();
                System.out.printf("Transcription: %s%n", alternative.getTranscript());
            }
//            OperationFuture<LongRunningRecognizeResponse, LongRunningRecognizeMetadata> response =
//                    speech.longRunningRecognizeAsync(config, audio);
//            //STT가 완료될때까지 기다린다
//            while (!response.isDone()) {
//                System.out.println("Waiting for response...");
//                Thread.sleep(10000);
//            }
            //결과를 LIST로 받는다
//            List<SpeechRecognitionResult> results = response.get().getResultsList();
//            //결과를 출력한다
//            for (SpeechRecognitionResult result : results) {
//                // There can be several alternative transcripts for a given chunk of speech. Just use the
//                // first (most likely) one here.
//                SpeechRecognitionAlternative alternative = result.getAlternativesList().get(0);
//                System.out.printf("Transcription: %s%n", alternative.getTranscript());
//            }
        }
        //오디오 파일을 찾지 못했거나 SpeechClient.create()가 실패했거나 그외의 오류 검출
        catch (Exception e){
            e.printStackTrace();
        }
    }


    /*public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("stt")) {

                                try {
                                    //함수에 오디오 파일 경로를 넣어준다
                                    asyncRecognizeFile("C:/Users/K/AndroidStudioProjects/flutter_app/android/app/src/main/res/raw/audio.raw");
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                                //result.success("Hi From Java..");
                                result.success("complte");
                            }
                            // Note: this method is invoked on the main thread.
                            // TODO
                        }
                );
    }*/
    @Override
    protected void onCreate(Bundle savedInstanceState) {
      //verifyStoragePermissions(FlutterActivity);
    super.onCreate(savedInstanceState);


  }


   @Override
   public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine){
       GeneratedPluginRegistrant.registerWith(flutterEngine);
       new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
               .setMethodCallHandler(
                       (call, result) -> {
                           if (call.method.equals("stt")) {
                               final String song = call.argument("song");
                               System.out.println(song);
                               try {

                                   //함수에 오디오 파일 경로를 넣어준다
                                   asyncRecognizeFile(
                                           song
                                           //"/sdcard/Android/data/com.example.sttbasicui/files/flutter_audio_recorder_1590512148037.wav"
                                           );
                               } catch (Exception e) {
                                   e.printStackTrace();
                               }
                               //result.success("Hi From Java..");
                               result.success(speechresult);
                           }
                       }
               );
   }
}
