sealed class StudentBibliotecaState {}

class StudentBibliotecaInitial extends StudentBibliotecaState {}

class StudentBibliotecaLoading extends StudentBibliotecaState {}

class StudentBibliotecaLoaded extends StudentBibliotecaState {
  StudentBibliotecaLoaded(this.records, this.total);
  final List<dynamic> records;
  final int total;
}

class StudentBibliotecaError extends StudentBibliotecaState {
  StudentBibliotecaError(this.message);
  final String message;
}
