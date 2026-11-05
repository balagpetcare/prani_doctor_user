class AnimalWeightApiPaths {
  AnimalWeightApiPaths._();

  static const tapePreview = '/api/mobile/animals/weight/tape/preview';

  static String measurements(String animalId) =>
      '/api/mobile/animals/$animalId/weight/measurements';

  static String current(String animalId) =>
      '/api/mobile/animals/$animalId/weight/current';

  static String accuracy(String animalId) =>
      '/api/mobile/animals/$animalId/weight/accuracy';

  static String aiJobs(String animalId) =>
      '/api/mobile/animals/$animalId/weight/ai-jobs';

  static String aiJob(String animalId, String jobId) =>
      '/api/mobile/animals/$animalId/weight/ai-jobs/$jobId';
}
