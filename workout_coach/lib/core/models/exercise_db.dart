class BodyPartInfo {
  final String id;
  final String name;
  final String emoji;
  final List<ExerciseTemplate> exercises;

  const BodyPartInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.exercises,
  });
}

class ExerciseTemplate {
  final String name;
  final int defaultSets;
  final String defaultReps;
  final String description;

  const ExerciseTemplate({
    required this.name,
    required this.defaultSets,
    required this.defaultReps,
    required this.description,
  });
}

const bodyParts = [
  BodyPartInfo(
    id: 'chest',
    name: '가슴',
    emoji: '🫀',
    exercises: [
      ExerciseTemplate(name: '벤치프레스', defaultSets: 4, defaultReps: '8-10회', description: '바를 가슴 중앙으로 천천히 내리고 밀어 올린다'),
      ExerciseTemplate(name: '푸쉬업', defaultSets: 3, defaultReps: '15-20회', description: '몸을 일직선으로 유지하며 팔꿈치를 45도 각도로 굽힌다'),
      ExerciseTemplate(name: '인클라인 벤치프레스', defaultSets: 3, defaultReps: '10-12회', description: '벤치를 30-45도 기울여 상부 가슴을 집중 자극한다'),
      ExerciseTemplate(name: '덤벨 플라이', defaultSets: 3, defaultReps: '12-15회', description: '팔을 크게 벌려 가슴 근육을 스트레칭한다'),
      ExerciseTemplate(name: '딥스', defaultSets: 3, defaultReps: '10-15회', description: '몸을 약간 앞으로 기울여 가슴에 집중한다'),
      ExerciseTemplate(name: '케이블 크로스오버', defaultSets: 3, defaultReps: '12-15회', description: '케이블을 교차시켜 가슴 중앙을 수축한다'),
    ],
  ),
  BodyPartInfo(
    id: 'back',
    name: '등',
    emoji: '🧗',
    exercises: [
      ExerciseTemplate(name: '풀업', defaultSets: 4, defaultReps: '6-10회', description: '넓은 그립으로 잡고 가슴을 바 쪽으로 당긴다'),
      ExerciseTemplate(name: '바벨 로우', defaultSets: 4, defaultReps: '8-10회', description: '상체를 45도로 숙이고 바를 복부 쪽으로 당긴다'),
      ExerciseTemplate(name: '랫 풀다운', defaultSets: 3, defaultReps: '10-12회', description: '광배근에 집중하며 바를 가슴 위쪽으로 당긴다'),
      ExerciseTemplate(name: '시티드 케이블 로우', defaultSets: 3, defaultReps: '12회', description: '등을 곧게 세우고 복부 쪽으로 당긴다'),
      ExerciseTemplate(name: '데드리프트', defaultSets: 4, defaultReps: '5-8회', description: '허리를 중립으로 유지하며 무릎과 엉덩이를 동시에 편다'),
      ExerciseTemplate(name: '원암 덤벨 로우', defaultSets: 3, defaultReps: '10-12회', description: '벤치에 한 손을 짚고 덤벨을 옆구리 쪽으로 당긴다'),
    ],
  ),
  BodyPartInfo(
    id: 'legs',
    name: '하체',
    emoji: '🦵',
    exercises: [
      ExerciseTemplate(name: '스쿼트', defaultSets: 4, defaultReps: '8-12회', description: '발을 어깨 너비로 벌리고 허벅지가 바닥과 평행할 때까지 내린다'),
      ExerciseTemplate(name: '레그프레스', defaultSets: 4, defaultReps: '10-15회', description: '발 위치에 따라 다른 부위 자극, 무릎이 발끝을 넘지 않게'),
      ExerciseTemplate(name: '런지', defaultSets: 3, defaultReps: '12회(각)', description: '앞발 무릎이 90도가 되도록 내려간다'),
      ExerciseTemplate(name: '레그 컬', defaultSets: 3, defaultReps: '12-15회', description: '햄스트링을 집중 자극, 천천히 내린다'),
      ExerciseTemplate(name: '레그 익스텐션', defaultSets: 3, defaultReps: '12-15회', description: '대퇴사두근을 집중 자극, 끝까지 완전 수축한다'),
      ExerciseTemplate(name: '카프레이즈', defaultSets: 4, defaultReps: '15-20회', description: '발뒤꿈치를 최대한 높이 올리고 2초 유지'),
      ExerciseTemplate(name: '힙 쓰러스트', defaultSets: 4, defaultReps: '12-15회', description: '벤치에 등을 기대고 엉덩이를 최대한 높이 밀어 올린다'),
    ],
  ),
  BodyPartInfo(
    id: 'shoulders',
    name: '어깨',
    emoji: '🏋️',
    exercises: [
      ExerciseTemplate(name: '숄더프레스', defaultSets: 4, defaultReps: '8-12회', description: '바를 귀 옆에서 시작해 머리 위로 밀어 올린다'),
      ExerciseTemplate(name: '사이드 레터럴레이즈', defaultSets: 3, defaultReps: '12-15회', description: '팔꿈치를 살짝 굽히고 어깨 높이까지 올린다'),
      ExerciseTemplate(name: '프론트 레이즈', defaultSets: 3, defaultReps: '12-15회', description: '덤벨을 앞으로 어깨 높이까지 들어 올린다'),
      ExerciseTemplate(name: '페이스풀', defaultSets: 3, defaultReps: '15회', description: '케이블을 얼굴 쪽으로 당겨 후면 삼각근을 자극한다'),
      ExerciseTemplate(name: '리어 델트 플라이', defaultSets: 3, defaultReps: '12-15회', description: '상체를 숙이고 팔을 옆으로 펼쳐 후면 어깨를 자극한다'),
    ],
  ),
  BodyPartInfo(
    id: 'arms',
    name: '팔',
    emoji: '💪',
    exercises: [
      ExerciseTemplate(name: '바벨 컬', defaultSets: 3, defaultReps: '10-12회', description: '팔꿈치를 고정하고 이두근으로만 들어 올린다'),
      ExerciseTemplate(name: '해머 컬', defaultSets: 3, defaultReps: '12회', description: '손목을 중립으로 유지하며 덤벨을 들어 올린다'),
      ExerciseTemplate(name: '트라이셉스 딥', defaultSets: 3, defaultReps: '10-15회', description: '팔꿈치가 뒤를 향하도록 유지하며 내린다'),
      ExerciseTemplate(name: '케이블 푸쉬다운', defaultSets: 3, defaultReps: '12-15회', description: '팔꿈치를 몸에 붙이고 삼두근으로 민다'),
      ExerciseTemplate(name: '스컬크러셔', defaultSets: 3, defaultReps: '10-12회', description: '바를 이마 쪽으로 내렸다가 삼두근으로 민다'),
      ExerciseTemplate(name: '컨센트레이션 컬', defaultSets: 3, defaultReps: '12회(각)', description: '팔꿈치를 허벅지에 고정하고 이두근을 완전 수축한다'),
    ],
  ),
  BodyPartInfo(
    id: 'core',
    name: '복근',
    emoji: '🔥',
    exercises: [
      ExerciseTemplate(name: '플랭크', defaultSets: 3, defaultReps: '60초', description: '몸을 일직선으로 유지하며 복부에 힘을 준다'),
      ExerciseTemplate(name: '크런치', defaultSets: 3, defaultReps: '20회', description: '허리를 바닥에 붙이고 상복부만 들어 올린다'),
      ExerciseTemplate(name: '레그레이즈', defaultSets: 3, defaultReps: '15회', description: '다리를 천천히 내려 하복부를 자극한다'),
      ExerciseTemplate(name: '러시안 트위스트', defaultSets: 3, defaultReps: '20회(각)', description: '상체를 좌우로 회전하며 옆구리를 자극한다'),
      ExerciseTemplate(name: '바이시클 크런치', defaultSets: 3, defaultReps: '20회(각)', description: '팔꿈치와 반대쪽 무릎을 교차하며 복사근을 자극한다'),
      ExerciseTemplate(name: '마운틴클라이머', defaultSets: 3, defaultReps: '30회(각)', description: '플랭크 자세에서 무릎을 교대로 가슴 쪽으로 당긴다'),
    ],
  ),
  BodyPartInfo(
    id: 'cardio',
    name: '유산소',
    emoji: '🏃',
    exercises: [
      ExerciseTemplate(name: '러닝', defaultSets: 1, defaultReps: '30분', description: '일정한 속도로 유지하며 유산소 능력을 향상시킨다'),
      ExerciseTemplate(name: '줄넘기', defaultSets: 3, defaultReps: '3분', description: '발목 스프링을 활용해 가볍게 뛴다'),
      ExerciseTemplate(name: '버피', defaultSets: 3, defaultReps: '10-15회', description: '스쿼트-플랭크-점프를 연속으로 수행한다'),
      ExerciseTemplate(name: '자전거', defaultSets: 1, defaultReps: '30분', description: '저항을 조절하며 일정한 RPM을 유지한다'),
      ExerciseTemplate(name: '케틀벨 스윙', defaultSets: 3, defaultReps: '15-20회', description: '엉덩이 힘으로 케틀벨을 어깨 높이까지 올린다'),
      ExerciseTemplate(name: '점프 스쿼트', defaultSets: 3, defaultReps: '12회', description: '스쿼트 후 최대한 높이 점프하고 부드럽게 착지한다'),
    ],
  ),
];

const weekDayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

List<String> getDefaultDays(int count) {
  const presets = [
    ['월요일'],
    ['월요일', '목요일'],
    ['월요일', '수요일', '금요일'],
    ['월요일', '화요일', '목요일', '토요일'],
    ['월요일', '화요일', '수요일', '목요일', '금요일'],
    ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일'],
    ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
  ];
  return presets[(count - 1).clamp(0, 6)];
}
