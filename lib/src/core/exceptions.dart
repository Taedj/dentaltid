import 'dart:developer' as developer;

/// Custom exceptions for the DentalTid application
class DatabaseException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  DatabaseException(this.message, {this.details, this.originalError});

  @override
  String toString() =>
      'DatabaseException: $message${details != null ? '\nDetails: $details' : ''}';
}

class ValidationException implements Exception {
  final String message;
  final String field;

  ValidationException(this.message, {this.field = ''});

  @override
  String toString() =>
      'ValidationException: $message${field.isNotEmpty ? ' (Field: $field)' : ''}';
}

class DuplicateEntryException implements Exception {
  final String message;
  final String entity;
  final String duplicateValue;

  DuplicateEntryException(
    this.message, {
    this.entity = '',
    this.duplicateValue = '',
  });

  @override
  String toString() =>
      'DuplicateEntryException: $message${entity.isNotEmpty ? ' (Entity: $entity)' : ''}${duplicateValue.isNotEmpty ? ' (Value: $duplicateValue)' : ''}';
}

class NotFoundException implements Exception {
  final String message;
  final String entity;
  final dynamic id;

  NotFoundException(this.message, {this.entity = '', this.id});

  @override
  String toString() =>
      'NotFoundException: $message${entity.isNotEmpty ? ' (Entity: $entity)' : ''}${id != null ? ' (ID: $id)' : ''}';
}

class ServiceException implements Exception {
  final String message;
  final String service;
  final dynamic originalError;

  ServiceException(this.message, {this.service = '', this.originalError});

  @override
  String toString() =>
      'ServiceException: $message${service.isNotEmpty ? ' (Service: $service)' : ''}${originalError != null ? '\nOriginal Error: ${originalError.toString()}' : ''}';
}

/// Error handler utility class
class ErrorHandler {
  static bool _isDebugMode = true; // Set to false for production

  static void setDebugMode(bool debug) {
    _isDebugMode = debug;
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error is DatabaseException) {
      return 'Database Error: ${error.message}';
    } else if (error is ValidationException) {
      return 'Validation Error: ${error.message}';
    } else if (error is DuplicateEntryException) {
      return error.message;
    } else if (error is NotFoundException) {
      return 'Not Found: ${error.message}';
    } else if (error is ServiceException) {
      if (_isDebugMode && error.originalError != null) {
        return 'Service Error: ${error.message}\nDebug: ${error.originalError.toString()}';
      }
      return 'Service Error: ${error.message}';
    } else if (error is FormatException) {
      return 'Invalid format: Please check your input values';
    } else if (error is ArgumentError) {
      return 'Invalid argument: ${error.message}';
    } else {
      if (_isDebugMode) {
        return 'Unexpected error: ${error.toString()}';
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // In a real app, you might want to send this to a logging service
    developer.log('=== ERROR LOG ===', name: 'ErrorHandler');
    developer.log('Timestamp: ${DateTime.now()}', name: 'ErrorHandler');
    developer.log(
      'Error: ${error.toString()}',
      name: 'ErrorHandler',
      error: error,
    );
    if (stackTrace != null) {
      developer.log(
        'Stack Trace: $stackTrace',
        name: 'ErrorHandler',
        stackTrace: stackTrace,
      );
    }
    developer.log('================', name: 'ErrorHandler');
  }
}
