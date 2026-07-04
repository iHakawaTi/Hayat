class Question {
  final String id;
  final String label;
  final String type; // 'yes_no', 'checkbox', 'text'
  final String? category;

  const Question({
    required this.id,
    required this.label,
    required this.type,
    this.category,
  });
}

const List<Question> mohForm = [
  Question(id: 'feels_healthy', label: 'Do you feel healthy?', type: 'yes_no'),
  Question(id: 'refused_before', label: 'Have you been refused before?', type: 'yes_no'),
  Question(id: 'jaundice', label: 'Jaundice or Hepatitis?', type: 'yes_no'),
  Question(id: 'malaria', label: 'Malaria?', type: 'yes_no'),
  Question(id: 'typhoid', label: 'Typhoid/Malta Fever?', type: 'yes_no'),
  Question(id: 'dentist', label: 'Dentist visit in last 3 days?', type: 'yes_no'),
  Question(id: 'pregnant', label: 'Pregnant (last 6 months)?', type: 'yes_no'),
];

const List<Question> khccForm = [
  Question(id: 'diff_name', label: 'Attempted to donate with different name?', type: 'yes_no'),
  Question(id: 'fainting', label: 'History of fainting?', type: 'yes_no'),
  Question(id: 'travel', label: 'Travel outside country?', type: 'yes_no'),
  Question(id: 'tattoo_piercing', label: 'Tattoo or Ear Piercing?', type: 'yes_no'),
  Question(id: 'cupping', label: 'Cupping (Hijama)?', type: 'yes_no'),
  Question(id: 'cancer', label: 'Cancer?', type: 'checkbox', category: 'disease'),
];

const List<Question> juhForm = [
  Question(id: 'antibiotics', label: 'Antibiotics in last 48 hours?', type: 'yes_no'),
  Question(id: 'medications_72h', label: 'Medications in last 72 hours?', type: 'yes_no'),
  Question(id: 'surgery', label: 'Surgery?', type: 'yes_no'),
];

final Map<String, List<Question>> hospitalForms = {
  'MOH': mohForm,
  'KHCC': khccForm,
  'JUH': juhForm,
  'DEFAULT': mohForm, // Fallback
};
