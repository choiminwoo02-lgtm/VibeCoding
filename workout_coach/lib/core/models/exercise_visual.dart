import 'package:flutter/material.dart';

enum MuscleGroup { chest, back, legs, shoulders, arms, core, cardio, fullBody }

class ExerciseVisual {
  static MuscleGroup fromFocus(String focus) {
    if (focus.contains('가슴') || focus.contains('흉')) return MuscleGroup.chest;
    if (focus.contains('등') || focus.contains('광배') || focus.contains('배근')) return MuscleGroup.back;
    if (focus.contains('하체') || focus.contains('다리') || focus.contains('엉덩')) return MuscleGroup.legs;
    if (focus.contains('어깨') || focus.contains('숄더')) return MuscleGroup.shoulders;
    if (focus.contains('팔') || focus.contains('이두') || focus.contains('삼두')) return MuscleGroup.arms;
    if (focus.contains('복') || focus.contains('코어')) return MuscleGroup.core;
    if (focus.contains('유산소') || focus.contains('달리') || focus.contains('심폐')) return MuscleGroup.cardio;
    return MuscleGroup.fullBody;
  }

  static MuscleGroup fromName(String name) {
    if (['벤치', '푸쉬업', '푸시업', '딥스', '플라이', '인클라인', '케이블 크로스', '체스트'].any(name.contains)) {
      return MuscleGroup.chest;
    }
    if (['풀업', '바벨 로우', '랫 풀', '데드리프트', '친업', '원암', '시티드 케이블'].any(name.contains)) {
      return MuscleGroup.back;
    }
    if (['스쿼트', '런지', '레그', '카프레이즈', '힙 쓰러스트', '햄스트링'].any(name.contains)) {
      return MuscleGroup.legs;
    }
    if (['숄더프레스', '레터럴레이즈', '레이즈', '페이스풀', '리어 델트'].any(name.contains)) {
      return MuscleGroup.shoulders;
    }
    if (['컬', '트라이셉', '스컬크러셔', '푸쉬다운', '컨센트레이션'].any(name.contains)) {
      return MuscleGroup.arms;
    }
    if (['플랭크', '크런치', '레그레이즈', '러시안 트위스트', '바이시클', '마운틴클라이머'].any(name.contains)) {
      return MuscleGroup.core;
    }
    if (['러닝', '줄넘기', '버피', '자전거', '케틀벨 스윙', '점프 스쿼트'].any(name.contains)) {
      return MuscleGroup.cardio;
    }
    return MuscleGroup.fullBody;
  }

  static MuscleGroup detect(String exerciseName, [String? focus]) {
    if (focus != null) {
      final g = fromFocus(focus);
      if (g != MuscleGroup.fullBody) return g;
    }
    return fromName(exerciseName);
  }

  static Color getColor(MuscleGroup group) => switch (group) {
        MuscleGroup.chest => const Color(0xFFE74C3C),
        MuscleGroup.back => const Color(0xFF2980B9),
        MuscleGroup.legs => const Color(0xFF27AE60),
        MuscleGroup.shoulders => const Color(0xFFE67E22),
        MuscleGroup.arms => const Color(0xFF8E44AD),
        MuscleGroup.core => const Color(0xFFF39C12),
        MuscleGroup.cardio => const Color(0xFFE91E63),
        MuscleGroup.fullBody => const Color(0xFF546E7A),
      };

  static String getEmoji(MuscleGroup group) => switch (group) {
        MuscleGroup.chest => '🫀',
        MuscleGroup.back => '🧗',
        MuscleGroup.legs => '🦵',
        MuscleGroup.shoulders => '🏋️',
        MuscleGroup.arms => '💪',
        MuscleGroup.core => '🔥',
        MuscleGroup.cardio => '🏃',
        MuscleGroup.fullBody => '⚡',
      };

  static String getLabel(MuscleGroup group) => switch (group) {
        MuscleGroup.chest => '가슴',
        MuscleGroup.back => '등',
        MuscleGroup.legs => '하체',
        MuscleGroup.shoulders => '어깨',
        MuscleGroup.arms => '팔',
        MuscleGroup.core => '복근',
        MuscleGroup.cardio => '유산소',
        MuscleGroup.fullBody => '전신',
      };

  static String _px(int id) =>
      'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=400&h=300&fit=crop';

  static final Map<String, String> _exerciseImages = {
    // 가슴
    '벤치프레스':          _px(4853666),
    '푸쉬업':              _px(176782),
    '인클라인 벤치프레스':  _px(6922168),
    '덤벨 플라이':         _px(3839310),
    '딥스':               _px(4803875),
    '케이블 크로스오버':    _px(10754972),
    // 등
    '풀업':               _px(9644816),
    '바벨 로우':           _px(3025027),
    '랫 풀다운':           _px(18060085),
    '시티드 케이블 로우':   _px(6539827),
    '데드리프트':          _px(4853280),
    '원암 덤벨 로우':      _px(10021279),
    // 하체
    '스쿼트':             _px(4662331),
    '레그프레스':          _px(6844939),
    '런지':               _px(8770407),
    '레그 컬':            _px(4384679),
    '레그 익스텐션':       _px(3076512),
    '카프레이즈':          _px(13965339),
    '힙 쓰러스트':         _px(6516221),
    // 어깨
    '숄더프레스':          _px(7289370),
    '사이드 레터럴레이즈':  _px(6339688),
    '프론트 레이즈':       _px(29793977),
    '페이스풀':            _px(6285184),
    '리어 델트 플라이':    _px(3839506),
    // 팔
    '바벨 컬':            _px(14085138),
    '해머 컬':            _px(9073246),
    '트라이셉스 딥':       _px(4803913),
    '케이블 푸쉬다운':     _px(5327467),
    '스컬크러셔':          _px(4803892),
    '컨센트레이션 컬':     _px(14524650),
    // 복근
    '플랭크':             _px(4945275),
    '크런치':             _px(6516225),
    '레그레이즈':          _px(4971061),
    '러시안 트위스트':     _px(8038625),
    '바이시클 크런치':     _px(7721988),
    '마운틴클라이머':      _px(8038636),
    // 유산소
    '러닝':               _px(2827400),
    '줄넘기':             _px(4945535),
    '버피':               _px(30246184),
    '자전거':             _px(19254708),
    '케틀벨 스윙':         _px(13106615),
    '점프 스쿼트':         _px(4662333),
  };

  static String getExerciseImageUrl(String exerciseName) =>
      _exerciseImages[exerciseName] ?? getImageUrl(fromName(exerciseName));

  static String getImageUrl(MuscleGroup group) => switch (group) {
        MuscleGroup.chest =>
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop&q=80',
        MuscleGroup.back =>
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop&q=80',
        MuscleGroup.legs =>
          'https://images.unsplash.com/photo-1567598508481-65985588e295?w=400&h=300&fit=crop&q=80',
        MuscleGroup.shoulders =>
          'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=300&fit=crop&q=80',
        MuscleGroup.arms =>
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop&q=80',
        MuscleGroup.core =>
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&h=300&fit=crop&q=80',
        MuscleGroup.cardio =>
          'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&h=300&fit=crop&q=80',
        MuscleGroup.fullBody =>
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&h=300&fit=crop&q=80',
      };
}
