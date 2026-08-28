export interface Patient {
  id: string
  name: string
  age: number
  gender: 'Male' | 'Female'
  diabetesType: 'Type 1' | 'Type 2'
  yearsSinceDiagnosis: number
  village: string
}

const villages = ['Sironj', 'Betul', 'Chhindwara', 'Sehore', 'Raisen', 'Vidisha', 'Harda', 'Dewas']
const firstNames = ['Ramesh', 'Sunita', 'Ashok', 'Kavita', 'Manoj', 'Geeta', 'Suresh', 'Rekha', 'Vijay', 'Anita', 'Dinesh', 'Pooja', 'Mahesh', 'Shanti', 'Ravi', 'Meena']
const lastNames = ['Patel', 'Sharma', 'Verma', 'Yadav', 'Chouhan', 'Rathore', 'Mishra', 'Tiwari']

function seededPatients(count: number): Patient[] {
  const patients: Patient[] = []
  for (let i = 0; i < count; i++) {
    const first = firstNames[i % firstNames.length]
    const last = lastNames[(i * 3) % lastNames.length]
    patients.push({
      id: `PXT-${String(1000 + i)}`,
      name: `${first} ${last}`,
      age: 38 + ((i * 7) % 40),
      gender: i % 2 === 0 ? 'Male' : 'Female',
      diabetesType: i % 5 === 0 ? 'Type 1' : 'Type 2',
      yearsSinceDiagnosis: 1 + ((i * 3) % 18),
      village: villages[i % villages.length],
    })
  }
  return patients
}

export const mockPatients: Patient[] = seededPatients(32)
