-- ==============================================================================
-- AGRIVA MASTER SEED DATA (5 Tamil Nadu Pilot Districts)
-- ==============================================================================

-- 1. Districts
INSERT INTO districts (id, name, state_code) VALUES
('district-erode', 'Erode', 'TN'),
('district-tiruppur', 'Tiruppur', 'TN'),
('district-thanjavur', 'Thanjavur', 'TN'),
('district-tiruvarur', 'Tiruvarur', 'TN'),
('district-madurai', 'Madurai', 'TN')
ON CONFLICT (id) DO NOTHING;

-- 2. Procurement Centres (13 Mandis)
INSERT INTO procurement_centres 
(id, name, code, district_id, taluk, latitude, longitude, daily_processing_capacity_q, storage_capacity_q, processing_lanes_total, processing_lanes_active, status) 
VALUES
('centre-erode-01', 'Erode Regulated Market Hub', 'OP-Erode-01', 'district-erode', 'Erode', 11.3410, 77.7172, 1500.0, 3000.0, 3, 3, 'open'),
('centre-erode-02', 'Perundurai Grain Mandi', 'OP-Erode-02', 'district-erode', 'Perundurai', 11.2754, 77.5828, 1200.0, 2400.0, 2, 2, 'open'),
('centre-erode-03', 'Gobichettipalayam Centre', 'OP-Erode-03', 'district-erode', 'Gobichettipalayam', 11.4549, 77.4379, 1000.0, 2000.0, 2, 2, 'open'),
('centre-tiruppur-01', 'Tiruppur Central APMC Depot', 'OP-Tiruppur-01', 'district-tiruppur', 'Tiruppur', 11.1085, 77.3411, 1400.0, 2800.0, 3, 3, 'open'),
('centre-tiruppur-02', 'Dharapuram Grain Centre', 'OP-Tiruppur-02', 'district-tiruppur', 'Dharapuram', 10.7289, 77.5262, 1100.0, 2200.0, 2, 2, 'open'),
('centre-tiruppur-03', 'Kangeyam Procurement Hub', 'OP-Tiruppur-03', 'district-tiruppur', 'Kangeyam', 11.0055, 77.5594, 1200.0, 2400.0, 2, 2, 'open'),
('centre-thanjavur-01', 'Thanjavur Main Direct Purchase Centre', 'OP-Thanjavur-01', 'district-thanjavur', 'Thanjavur', 10.7870, 79.1378, 2000.0, 4500.0, 4, 4, 'open'),
('centre-thanjavur-02', 'Kumbakonam Modern DPC', 'OP-Thanjavur-02', 'district-thanjavur', 'Kumbakonam', 10.9602, 79.3845, 1600.0, 3200.0, 3, 3, 'open'),
('centre-thanjavur-03', 'Pattukkottai Coastal Depot', 'OP-Thanjavur-03', 'district-thanjavur', 'Pattukkottai', 10.4264, 79.3175, 1300.0, 2600.0, 2, 2, 'open'),
('centre-tiruvarur-01', 'Tiruvarur Central Silo Hub', 'OP-Tiruvarur-01', 'district-tiruvarur', 'Tiruvarur', 10.7725, 79.6365, 1800.0, 4000.0, 3, 3, 'open'),
('centre-tiruvarur-02', 'Mannargudi Delta APMC Mandi', 'OP-Tiruvarur-02', 'district-tiruvarur', 'Mannargudi', 10.6637, 79.4478, 1400.0, 2800.0, 2, 2, 'open'),
('centre-madurai-01', 'Madurai Agricultural Regulated Market', 'OP-Madurai-01', 'district-madurai', 'Madurai North', 9.9252, 78.1198, 1500.0, 3000.0, 3, 3, 'open'),
('centre-madurai-02', 'Usilampatti Grain Terminal', 'OP-Madurai-02', 'district-madurai', 'Usilampatti', 9.9702, 77.7942, 1000.0, 2000.0, 2, 2, 'open')
ON CONFLICT (id) DO NOTHING;

-- 3. Crops & Official Statutory MSP Rates (2024-2026)
INSERT INTO crops (id, name, local_names, msp, season) VALUES
('crop-paddy-common', 'Paddy (Common)', '{"ta": "நெல் (சாதாரண ரகம்)"}', 2300.00, 'kharif'),
('crop-paddy-grade-a', 'Paddy (Grade A)', '{"ta": "நெல் (கிரேடு ஏ)"}', 2320.00, 'kharif'),
('crop-maize', 'Maize (Corn)', '{"ta": "மக்காச்சோளம்"}', 2225.00, 'kharif'),
('crop-ragi', 'Finger Millet (Ragi)', '{"ta": "கேழ்வரகு"}', 4290.00, 'kharif'),
('crop-jowar', 'Sorghum (Jowar Hybrid)', '{"ta": "சோளம்"}', 3371.00, 'kharif'),
('crop-bajra', 'Pearl Millet (Bajra)', '{"ta": "கம்பு"}', 2625.00, 'kharif'),
('crop-urad', 'Black Gram (Urad)', '{"ta": "உளுந்து"}', 7400.00, 'rabi'),
('crop-moong', 'Green Gram (Moong)', '{"ta": "பாசிப்பயறு"}', 8682.00, 'kharif'),
('crop-cotton', 'Medium Staple Cotton', '{"ta": "பருத்தி"}', 7121.00, 'kharif')
ON CONFLICT (id) DO NOTHING;

-- 4. Admin Users (Password: agriva123 -> $2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym)
INSERT INTO admin_users (id, name, role, employee_id, password_hash, centre_id, district) VALUES
('user-dt-erode', 'Dr. V. Kalanidhi IAS (District Collector)', 'districtAdmin', 'DT-Erode', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-erode'),
('user-dt-tiruppur', 'Thiru T. Christuraj IAS', 'districtAdmin', 'DT-Tiruppur', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-tiruppur'),
('user-dt-thanjavur', 'Thiru Deepak Jacob IAS', 'districtAdmin', 'DT-Thanjavur', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-thanjavur'),
('user-op-erode-01', 'K. Sakthivel (Chief Inspector)', 'centreOperator', 'OP-Erode-01', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', 'centre-erode-01', 'district-erode'),
('user-op-thanjavur-01', 'M. Anbarasan (Yard In-Charge)', 'centreOperator', 'OP-Thanjavur-01', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', 'centre-thanjavur-01', 'district-thanjavur'),
('user-st-admin', 'State Principal Secretary - Food & Civil Supplies', 'stateAdmin', 'ST-Admin', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- 5. Demo Farmers
INSERT INTO farmers 
(id, farmer_code, name, phone, preferred_language, door_no, street, village, taluk, district, pincode, assigned_centre_id, distance_km, estimated_travel_minutes, aadhaar_hash, aadhaar_masked, bank_account_hash, bank_account_masked, bank_ifsc, verification_status) 
VALUES
('farmer-murugan', 'FRM-1001', 'R. Murugan', '9876543210', 'ta', '4/12B', 'Mettu Street', 'Modakkurichi', 'Erode', 'district-erode', '638104', 'centre-erode-01', 8.5, 22, 'hash_murugan_aadhaar', 'XXXX-XXXX-4512', 'hash_murugan_bank', 'XXXX4589', 'SBIN0001234', 'approved'),
('farmer-palanisamy', 'FRM-1002', 'M. Palanisamy', '9876543212', 'ta', '12', 'Kavindapadi Road', 'Bhavani', 'Erode', 'district-erode', '638301', 'centre-erode-01', 14.2, 35, 'hash_palanisamy_aadhaar', 'XXXX-XXXX-8921', 'hash_palanisamy_bank', 'XXXX7812', 'IOBA0000456', 'approved'),
('farmer-senthil', 'FRM-1003', 'K. Senthil Kumar', '9876543211', 'ta', '22/1', 'North Car Street', 'Perundurai', 'Erode', 'district-erode', '638052', 'centre-erode-02', 4.1, 12, 'hash_senthil_aadhaar', 'XXXX-XXXX-3344', 'hash_senthil_bank', 'XXXX9901', 'CANB0002100', 'pendingApproval'),
('farmer-thangavel', 'FRM-1004', 'A. Thangavel', '9876543213', 'ta', '7/88', 'Pillayar Kovil St', 'Gobichettipalayam', 'Erode', 'district-erode', '638452', 'centre-erode-03', 18.0, 42, 'hash_thangavel_aadhaar', 'XXXX-XXXX-7788', 'hash_thangavel_bank', 'XXXX3321', 'UBIN0543210', 'escalatedToDistrict')
ON CONFLICT (id) DO NOTHING;

-- 6. Land Records
INSERT INTO land_records (id, farmer_id, patta_number, survey_number, area_hectares, ownership_type, is_verified) VALUES
('land-m-01', 'farmer-murugan', 'PATTA-9081', 'SF-142/2A', 2.45, 'owner', TRUE),
('land-p-01', 'farmer-palanisamy', 'PATTA-6612', 'SF-89/1B', 3.80, 'owner', TRUE),
('land-s-01', 'farmer-senthil', 'PATTA-3410', 'SF-201/4', 1.60, 'owner', FALSE)
ON CONFLICT (id) DO NOTHING;
