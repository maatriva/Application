export interface CreateBabyInput {
  name: string;
  gender: string;
  dateOfBirth: string; // ISO string format (e.g. YYYY-MM-DD or full ISO)
  bloodGroup?: string;
  birthWeight?: number;
  birthHeight?: number;
  photoUrl?: string;
}

export interface UpdateBabyInput {
  name?: string;
  gender?: string;
  dateOfBirth?: string; // ISO string format
  bloodGroup?: string;
  birthWeight?: number;
  birthHeight?: number;
  photoUrl?: string;
}
