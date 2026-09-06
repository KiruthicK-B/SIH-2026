"""Canonical field registry for OneDesk's common government data model.

Small deliberately — a real deployment's schema registry would be a versioned,
governed service (see HLD.md §2.6); this is the MVP-scale in-memory equivalent,
enough to prove the mapping-suggestion pattern without building schema governance.
"""

CANONICAL_FIELDS = [
    {"field": "name", "description": "Full legal name of the citizen"},
    {"field": "dateOfBirth", "description": "Date of birth, ISO 8601 format"},
    {"field": "citizenId", "description": "Platform master citizen identifier (OneDesk ID)"},
    {"field": "address", "description": "Residential or business address"},
    {"field": "gender", "description": "Gender"},
    {"field": "phoneNumber", "description": "Contact mobile number"},
    {"field": "email", "description": "Contact email address"},
    {"field": "income", "description": "Annual income"},
    {"field": "businessName", "description": "Registered business name"},
    {"field": "businessRegistrationNumber", "description": "Business registration number"},
    {"field": "propertyId", "description": "Property or land parcel identifier"},
    {"field": "department", "description": "Owning government department"},
]

# Known synonyms seen across department schemas — checked before falling back to
# fuzzy string matching, since exact domain synonyms (e.g. "dob" -> dateOfBirth)
# often score lower on generic string similarity than they should.
KNOWN_SYNONYMS = {
    "full_name": "name",
    "fullname": "name",
    "citizen_name": "name",
    "applicant_name": "name",
    "dob": "dateOfBirth",
    "date_of_birth": "dateOfBirth",
    "birthdate": "dateOfBirth",
    "birth_date": "dateOfBirth",
    "citizen_identifier": "citizenId",
    "citizen_id": "citizenId",
    "beneficiary_id": "citizenId",
    "master_id": "citizenId",
    "addr": "address",
    "addr_line1": "address",
    "address_line1": "address",
    "residential_address": "address",
    "mobile": "phoneNumber",
    "mobile_number": "phoneNumber",
    "phone": "phoneNumber",
    "contact_number": "phoneNumber",
    "annual_income": "income",
    "income_amount": "income",
    "biz_name": "businessName",
    "company_name": "businessName",
    "enterprise_name": "businessName",
    "biz_reg_no": "businessRegistrationNumber",
    "registration_number": "businessRegistrationNumber",
    "reg_no": "businessRegistrationNumber",
    "property_number": "propertyId",
    "parcel_id": "propertyId",
    "survey_number": "propertyId",
    "dept": "department",
    "owning_department": "department",
    "source_dept": "department",
}
