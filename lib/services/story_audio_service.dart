import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StoryAudioService {
  late FlutterTts _tts;

  bool isPlaying = false;
  bool isPaused = false;
  bool isLoading = false;

  // كولباك لتحديث الواجهة عند تغير حالة الصوت
  final VoidCallback onStateChanged;

  StoryAudioService({required this.onStateChanged}) {
    _initTTS();
  }

  // ─── تهيئة flutter_tts المحلية ───────────────────────────────────────────
  void _initTTS() async {
    _tts = FlutterTts();
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    
    _tts.setCompletionHandler(() {
      _updateState(playing: false, paused: false, loading: false);
    });

    _tts.setCancelHandler(() {
      _updateState(playing: false, paused: false, loading: false);
    });

    _tts.setErrorHandler((_) {
      _updateState(playing: false, paused: false, loading: false);
    });
  }

  // ─── منطق التشغيل والتحكم ───────────────────────────────────────────────────
  Future<void> toggleAudio(String text) async {
    // 1. إيقاف مؤقت (Pause)
    if (isPlaying && !isPaused) {
      await _tts.pause();
      _updateState(paused: true);
      return;
    }

    // 2. استئناف التشغيل (Resume)
    if (isPlaying && isPaused) {
      await _tts.speak(text);
      _updateState(paused: false);
      return;
    }

    // 3. تشغيل جديد بالكامل
    _updateState(loading: true);
    await _tts.speak(text);
    _updateState(playing: true, paused: false, loading: false);
  }

  // إيقاف الصوت تماماً
  Future<void> stopAudio() async {
    await _tts.stop();
    _updateState(playing: false, paused: false, loading: false);
  }

  // تحديث الحالات وإشعار الواجهات (UI)
  void _updateState({bool? playing, bool? paused, bool? loading}) {
    if (playing != null) isPlaying = playing;
    if (paused != null) isPaused = paused;
    if (loading != null) isLoading = loading;
    onStateChanged(); // إعادة بناء الوجوه (Widgets) المرتبطة
  }

  // تنظيف الذاكرة عند التخلص من الخدمة
  void dispose() {
    _tts.stop();
  }
}