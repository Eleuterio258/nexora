sealed class StudentOcorrenciasState {}

class StudentOcorrenciasInitial extends StudentOcorrenciasState {}

class StudentOcorrenciasLoading extends StudentOcorrenciasState {}

class StudentOcorrenciasLoaded extends StudentOcorrenciasState {
  StudentOcorrenciasLoaded(this.data);
  final Map<String, dynamic> data;
}

class StudentOcorrenciasError extends StudentOcorrenciasState {
  StudentOcorrenciasError(this.message);
  final String message;
}
