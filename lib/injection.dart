import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/repositories/advicer_repo_impl.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

final sl = GetIt.instance;

Future<void> init() async {
  // Application
  sl.registerFactory<AdvicerCubit>(
    () => AdvicerCubit(advicerUseCases: sl()),
  );

  // Domain
  sl.registerFactory<AdvicerUseCases>(
    () => AdvicerUseCases(advicerRepo: sl()),
  );

  // Data
  sl.registerFactory<AdvicerRepo>(
    () => AdvicerRepoImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<AdvicerRemoteDataSource>(
    () => AdvicerRemoteDataSourceImpl(client: sl()),
  );

  // External
  sl.registerFactory<http.Client>(() => http.Client());
}
