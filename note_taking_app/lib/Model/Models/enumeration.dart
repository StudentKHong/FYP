enum ComponentType{
  note, task;

  static const Map<String, ComponentType> _componentMap = {
    'note': ComponentType.note,
    'task': ComponentType.task,
  };

  static ComponentType? convertFromString(String component) {
    // Remove leading and trailing spaces
    String cleanedComponent = component.toLowerCase().trim();

    // Remove trailing 's'
    if (cleanedComponent.endsWith('s')){
      cleanedComponent = cleanedComponent.substring(0, cleanedComponent.length - 1);
    }
    return _componentMap[cleanedComponent];
  }

  static String? convertToString(ComponentType componentType) {
    for (var component in _componentMap.entries) {
      if (component.value == componentType) return component.key;
    }
    return null;
  }
}

enum UserType {
  student,
  teacher,
  worker,
  guest;

  static const Map<String, UserType> _roleMap = {
    'student': UserType.student,
    'teacher': UserType.teacher,
    'worker': UserType.worker,
    'guest': UserType.guest
  };

  static UserType? convertRoleToUserType(String role) {
    final String cleanedRole = role.toLowerCase().trim();
    return _roleMap[cleanedRole];
  }

  static String? convertUserTypeToRole(UserType? userType) {
    for (var role in _roleMap.entries) {
      if (role.value == userType) return role.key;
    }
    return null;
  }
}

enum SortType {
  name,
  dateCreated
}

enum FilterType{
  dateCreated,
  dateModified
}

enum NoteFilterType{
  label,
  dateCreated,
  dateModified
}

enum TaskFilterType{
  label,
  dateCreated,
  dateModified,
  status
}

enum Status{
  unknown,
  pending,
  inProgress,
  completed;

  static const Map<String, Status> _statusMap = {
    'pending': Status.pending,
    'inProgress': Status.inProgress,
    'completed': Status.completed,
  };

  static Status convertFromString(String? status) {
    if (status == null) return Status.unknown;
    
    // Remove leading and trailing spaces
    String cleanedComponent = status.toLowerCase().trim();

    // Remove trailing 's'
    if (cleanedComponent.endsWith('s')){
      cleanedComponent = cleanedComponent.substring(0, cleanedComponent.length - 1);
    }
    return _statusMap[cleanedComponent] ?? Status.unknown;
  }

  static String convertToString(Status status) {
    for (var component in _statusMap.entries) {
      if (component.value == status) return component.key;
    }
    return 'unknown';
  }
}

enum ContentType{
  text,
  image,
  drawing
}