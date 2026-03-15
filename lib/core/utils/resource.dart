// lib/core/utils/resource.dart

sealed class Resource<T> {
  const Resource();
}

class ResourceLoading<T> extends Resource<T> {
  const ResourceLoading();
}

class ResourceSuccess<T> extends Resource<T> {
  final T data;
  const ResourceSuccess(this.data);
}

class ResourceError<T> extends Resource<T> {
  final String message;
  final Exception? exception;
  const ResourceError(this.message, {this.exception});
}

// Helper extensions
extension ResourceExtension<T> on Resource<T> {
  bool get isLoading => this is ResourceLoading<T>;
  bool get isSuccess => this is ResourceSuccess<T>;
  bool get isError => this is ResourceError<T>;

  T? get data => isSuccess ? (this as ResourceSuccess<T>).data : null;
  String? get errorMessage => isError ? (this as ResourceError<T>).message : null;
}
