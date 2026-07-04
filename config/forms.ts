// This file defines the specific questions for each bank's form.
// We will use this to generate the UI dynamically.

export type Question = {
    id: string;
    label: string;
    type: 'yes_no' | 'checkbox' | 'text';
    category?: 'disease' | 'history';
};

export const MOH_FORM: Question[] = [
    { id: 'feels_healthy', label: 'do you feel healthy?', type: 'yes_no' },
    { id: 'refused_before', label: 'Have you been refused before?', type: 'yes_no' },
    { id: 'jaundice', label: 'Jaundice or Hepatitis?', type: 'yes_no' },
    { id: 'malaria', label: 'Malaria?', type: 'yes_no' },
    { id: 'typhoid', label: 'Typhoid/Malta Fever?', type: 'yes_no' },
    { id: 'dentist', label: 'Dentist visit in last 3 days?', type: 'yes_no' }, // Specific to MOH
    { id: 'pregnant', label: 'Pregnant (last 6 months)?', type: 'yes_no' },
    // ... maps to Image 2
];

export const KHCC_FORM: Question[] = [
    { id: 'diff_name', label: 'Attempted to donate with different name?', type: 'yes_no' },
    { id: 'fainting', label: 'History of fainting?', type: 'yes_no' },
    { id: 'travel', label: 'Travel outside country?', type: 'yes_no' },
    { id: 'tattoo_piercing', label: 'Tattoo or Ear Piercing?', type: 'yes_no' },
    { id: 'cupping', label: 'Cupping (Hijama)?', type: 'yes_no' },
    { id: 'cancer', label: 'Cancer?', type: 'checkbox', category: 'disease' }, // KHCC specific focus
    // ... maps to Image 1
];

export const JUH_FORM: Question[] = [
    { id: 'antibiotics', label: 'Antibiotics in last 48 hours?', type: 'yes_no' }, // Specific to JUH
    { id: 'medications_72h', label: 'Medications in last 72 hours?', type: 'yes_no' },
    { id: 'surgery', label: 'Surgery?', type: 'yes_no' },
    // ... maps to Image 4
];

export const FORMS = {
    'MOH': MOH_FORM,
    'KHCC': KHCC_FORM,
    'JUH': JUH_FORM
};
