import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/hive/hive_configure.dart';
import '../models/job_hive_model.dart';
import '../models/job_model.dart';

/// Guarda vagas favoritas localmente (Hive) — o backend ainda não tem
/// endpoint de "guardar vaga" (ver JobRemoteDataSource), por isso este é o
/// único lado que persiste o estado de "guardado".
abstract class JobLocalDataSource {
  Future<void> saveJob(JobModel job);
  Future<void> unsaveJob(int jobId);
  Future<Set<int>> getSavedJobIds();
  Future<List<JobModel>> getSavedJobs();
}

class JobLocalDataSourceImpl implements JobLocalDataSource {
  Box<JobHiveModel> get _box => Hive.box<JobHiveModel>(HiveBoxes.jobs);

  @override
  Future<void> saveJob(JobModel job) async {
    await _box.put(job.id, _toHive(job));
  }

  @override
  Future<void> unsaveJob(int jobId) async {
    await _box.delete(jobId);
  }

  @override
  Future<Set<int>> getSavedJobIds() async => _box.keys.cast<int>().toSet();

  @override
  Future<List<JobModel>> getSavedJobs() async =>
      _box.values.map(_fromHive).toList();

  JobHiveModel _toHive(JobModel job) => JobHiveModel(
        id: job.id,
        title: job.title,
        company: job.company,
        location: job.location,
        type: job.type,
        category: job.category,
        description: job.description,
        salary: job.salary,
        logoUrl: job.logoUrl,
        postedAt: job.postedAt,
        isSaved: true,
      );

  JobModel _fromHive(JobHiveModel h) => JobModel(
        id: h.id,
        title: h.title,
        company: h.company,
        location: h.location,
        type: h.type,
        category: h.category,
        description: h.description,
        salary: h.salary,
        logoUrl: h.logoUrl,
        postedAt: h.postedAt,
        isSaved: true,
      );
}
