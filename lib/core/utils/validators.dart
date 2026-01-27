/// Form validation utilities
class Validators {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    return null;
  }
  
  /// Validate event title
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    
    if (value.length < 3) {
      return 'Title must be at least 3 characters';
    }
    
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    
    return null;
  }
  
  /// Validate description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 500) {
      return 'Description must be less than 500 characters';
    }
    
    return null;
  }
  
  /// Validate venue
  static String? validateVenue(String? value) {
    if (value == null || value.isEmpty) {
      return 'Venue is required';
    }
    
    if (value.length < 2) {
      return 'Venue must be at least 2 characters';
    }
    
    return null;
  }
  
  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate roll number (e.g., BSCSF23M01, BSSEF22F05)
  /// Pattern: [Program Code][Year][Gender][Roll]
  /// Program: 2-6 uppercase letters (BSCS, BSSE, MSCS, etc.)
  /// Year: 2 digits (21, 22, 23, etc.)
  /// Gender: M or F
  /// Roll: 2-3 digits (01-999)
  static String? validateRollNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Roll Number is required';
    }

    // Pattern: BSCSF23M01 style
    final rollRegex = RegExp(r'^[A-Z]{2,6}[0-9]{2}[MF][0-9]{2,3}$');

    if (!rollRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid format. Use pattern like BSCSF23M01';
    }

    return null;
  }

  /// Validate entry fee
  static String? validateEntryFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Entry fee is required';
    }

    final fee = double.tryParse(value);
    if (fee == null) {
      return 'Please enter a valid amount';
    }

    if (fee <= 0) {
      return 'Fee must be greater than 0';
    }

    if (fee > 100000) {
      return 'Fee cannot exceed 100,000 PKR';
    }

    return null;
  }
}
