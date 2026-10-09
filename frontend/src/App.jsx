import React, { useState, useEffect } from 'react';
import { Activity, Bed, Users, ShieldAlert, CheckCircle, RefreshCw, UserPlus, HeartPulse } from 'lucide-react';

const API_BASE = 'http://localhost:8080/api';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [occupancy, setOccupancy] = useState([]);
  const [departmentLoad, setDepartmentLoad] = useState([]);
  const [activeAllocations, setActiveAllocations] = useState([]);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  // Patient Intake Form State
  const [formData, setFormData] = useState({
    name: '',
    age: '',
    conditionDescription: '',
    triageScore: '1',
    requiredBedType: 'ICU',
    requiredEquipmentType: 'Ventilator',
    requiredSpecialization: 'Critical Care'
  });

  // Resource Match State
  const [patientIdToMatch, setPatientIdToMatch] = useState('1');
  const [matchResult, setMatchResult] = useState(null);

  // Fetch all dashboard & live data
  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [occRes, loadRes, allocRes] = await Promise.all([
        fetch(`${API_BASE}/dashboard/occupancy`),
        fetch(`${API_BASE}/dashboard/load`),
        fetch(`${API_BASE}/allocations/active`)
      ]);
      setOccupancy(await occRes.json());
      setDepartmentLoad(await loadRes.json());
      setActiveAllocations(await allocRes.json());
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  // Register Patient
  const handleRegister = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_BASE}/patients`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          age: parseInt(formData.age),
          triageScore: parseInt(formData.triageScore)
        })
      });
      const data = await res.json();
      setMessage(data.message || 'Patient registered!');
      fetchAllData();
    } catch (err) {
      setMessage('Failed to register patient.');
    }
  };

  // Find Resource Match
  const handleFindMatch = async () => {
    try {
      const res = await fetch(`${API_BASE}/allocations/match/${patientIdToMatch}`);
      if (!res.ok) {
        const errorData = await res.json();
        setMatchResult(null);
        setMessage(errorData.message || 'No resource match found.');
        return;
      }
      const data = await res.json();
      setMatchResult(data);
      setMessage('Resource match found!');
    } catch (err) {
      setMessage('Error running matching query.');
    }
  };

  // Confirm Allocation
  const handleConfirmAllocation = async () => {
    if (!matchResult) return;
    try {
      const res = await fetch(`${API_BASE}/allocations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patientId: matchResult.patient_id,
          bedId: matchResult.bed_id,
          equipmentId: matchResult.equipment_id,
          doctorId: matchResult.doctor_id
        })
      });
      const data = await res.json();
      setMessage(data.message || data.error);
      setMatchResult(null);
      fetchAllData();
    } catch (err) {
      setMessage('Failed to confirm allocation.');
    }
  };

  // Discharge Patient
  const handleDischarge = async (allocationId) => {
    try {
      const res = await fetch(`${API_BASE}/allocations/${allocationId}/discharge`, {
        method: 'PUT'
      });
      const data = await res.json();
      setMessage(data.message || data.error);
      fetchAllData();
    } catch (err) {
      setMessage('Failed to discharge patient.');
    }
  };

  return (
    <div className="min-vh-100 min-h-screen bg-slate-900 text-slate-100 flex flex-col font-sans">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-950/70 backdrop-blur px-8 py-4 flex items-center justify-between sticky top-0 z-20">
        <div className="flex items-center gap-3">
          <HeartPulse className="text-red-500 w-8 h-8 animate-pulse" />
          <h1 className="text-xl font-bold tracking-tight">Emergency Resource & Bed Allocation</h1>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchAllData}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-sm border border-slate-700 transition"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
          </button>
        </div>
      </header>

      {/* Navigation Bar */}
      <nav className="flex gap-4 px-8 pt-4 border-b border-slate-800 bg-slate-900">
        <button
          onClick={() => setActiveTab('dashboard')}
          className={`pb-3 px-2 font-medium text-sm flex items-center gap-2 border-b-2 transition ${
            activeTab === 'dashboard' ? 'border-blue-500 text-blue-400' : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          <Activity className="w-4 h-4" /> Live Dashboard
        </button>
        <button
          onClick={() => setActiveTab('intake')}
          className={`pb-3 px-2 font-medium text-sm flex items-center gap-2 border-b-2 transition ${
            activeTab === 'intake' ? 'border-blue-500 text-blue-400' : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          <UserPlus className="w-4 h-4" /> Patient Intake & Match
        </button>
        <button
          onClick={() => setActiveTab('allocations')}
          className={`pb-3 px-2 font-medium text-sm flex items-center gap-2 border-b-2 transition ${
            activeTab === 'allocations' ? 'border-blue-500 text-blue-400' : 'border-transparent text-slate-400 hover:text-slate-200'
          }`}
        >
          <Bed className="w-4 h-4" /> Active Allocations
        </button>
      </nav>

      {/* Global Status Banner */}
      {message && (
        <div className="mx-8 mt-4 p-3 bg-blue-950/60 border border-blue-800 rounded-lg text-blue-200 text-sm flex items-center justify-between">
          <span>{message}</span>
          <button onClick={() => setMessage('')} className="text-blue-400 hover:text-white font-bold text-xs">DISMISS</button>
        </div>
      )}

      {/* Main Tab Views */}
      <main className="p-8 flex-1">
        {activeTab === 'dashboard' && (
          <div className="space-y-8">
            {/* Bed Occupancy Grid */}
            <div>
              <h2 className="text-lg font-semibold mb-4 text-slate-200 flex items-center gap-2">
                <Bed className="text-blue-400 w-5 h-5" /> Current Bed Capacity (vw_current_occupancy)
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {occupancy.map((dept) => (
                  <div key={dept.department_id} className="p-5 rounded-xl bg-slate-800/60 border border-slate-700/80 shadow-sm">
                    <p className="font-bold text-base text-white">{dept.department_name}</p>
                    <p className="text-xs text-slate-400 mb-3">Total Beds: {dept.total_beds}</p>
                    <div className="space-y-1.5 text-xs">
                      <div className="flex justify-between">
                        <span className="text-red-400">Occupied:</span>
                        <span className="font-semibold">{dept.occupied_beds}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-emerald-400">Available:</span>
                        <span className="font-semibold">{dept.available_beds}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-amber-400">Cleaning:</span>
                        <span className="font-semibold">{dept.cleaning_beds}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Department Load Grid */}
            <div>
              <h2 className="text-lg font-semibold mb-4 text-slate-200 flex items-center gap-2">
                <Users className="text-indigo-400 w-5 h-5" /> Department Resource Load (vw_department_load)
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {departmentLoad.map((dept, idx) => (
                  <div key={idx} className="p-5 rounded-xl bg-slate-800/40 border border-slate-700/50">
                    <p className="font-bold text-white mb-2">{dept.department_name}</p>
                    <div className="space-y-1 text-xs text-slate-300">
                      <p>Active Bed Allocations: <span className="font-semibold text-white">{dept.occupied_beds || 0}</span> / {dept.total_beds}</p>
                      <p>Equipment in Use: <span className="font-semibold text-white">{dept.occupied_equipment || 0}</span> / {dept.total_equipment}</p>
                      <p>Active Patients: <span className="font-semibold text-blue-400">{dept.active_patients || 0}</span></p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'intake' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Register Patient Form */}
            <div className="bg-slate-800/60 border border-slate-700/80 p-6 rounded-xl">
              <h2 className="text-lg font-semibold mb-4 text-slate-200">Patient Emergency Intake</h2>
              <form onSubmit={handleRegister} className="space-y-4 text-sm">
                <div>
                  <label className="block text-xs text-slate-400 mb-1">Patient Full Name</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-white focus:outline-none focus:border-blue-500"
                    placeholder="e.g. Rahul Sharma"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs text-slate-400 mb-1">Age</label>
                    <input
                      type="number"
                      required
                      value={formData.age}
                      onChange={(e) => setFormData({ ...formData, age: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-white focus:outline-none focus:border-blue-500"
                      placeholder="45"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-slate-400 mb-1">Triage Priority (1-5)</label>
                    <select
                      value={formData.triageScore}
                      onChange={(e) => setFormData({ ...formData, triageScore: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-white focus:outline-none focus:border-blue-500"
                    >
                      <option value="1">1 - Resuscitation (Immediate)</option>
                      <option value="2">2 - Emergent</option>
                      <option value="3">3 - Urgent</option>
                      <option value="4">4 - Less Urgent</option>
                      <option value="5">5 - Non-Urgent</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label className="block text-xs text-slate-400 mb-1">Condition Description</label>
                  <input
                    type="text"
                    required
                    value={formData.conditionDescription}
                    onChange={(e) => setFormData({ ...formData, conditionDescription: e.target.value })}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2.5 text-white focus:outline-none focus:border-blue-500"
                    placeholder="Severe respiratory distress"
                  />
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <div>
                    <label className="block text-xs text-slate-400 mb-1">Bed Needed</label>
                    <select
                      value={formData.requiredBedType}
                      onChange={(e) => setFormData({ ...formData, requiredBedType: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2 text-xs text-white"
                    >
                      <option value="ICU">ICU</option>
                      <option value="Isolation">Isolation</option>
                      <option value="Trauma">Trauma</option>
                      <option value="General">General</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs text-slate-400 mb-1">Equipment</label>
                    <select
                      value={formData.requiredEquipmentType}
                      onChange={(e) => setFormData({ ...formData, requiredEquipmentType: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2 text-xs text-white"
                    >
                      <option value="Ventilator">Ventilator</option>
                      <option value="Defibrillator">Defibrillator</option>
                      <option value="ECG Monitor">ECG Monitor</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs text-slate-400 mb-1">Specialization</label>
                    <select
                      value={formData.requiredSpecialization}
                      onChange={(e) => setFormData({ ...formData, requiredSpecialization: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-lg p-2 text-xs text-white"
                    >
                      <option value="Critical Care">Critical Care</option>
                      <option value="Cardiology">Cardiology</option>
                      <option value="Trauma Surgery">Trauma Surgery</option>
                      <option value="General Medicine">General Medicine</option>
                    </select>
                  </div>
                </div>
                <button
                  type="submit"
                  className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 rounded-lg font-medium text-white transition mt-2"
                >
                  Register Patient
                </button>
              </form>
            </div>

            {/* Smart Matching Box */}
            <div className="bg-slate-800/60 border border-slate-700/80 p-6 rounded-xl flex flex-col justify-between">
              <div>
                <h2 className="text-lg font-semibold mb-4 text-slate-200">Smart Resource Allocation Matcher</h2>
                <p className="text-xs text-slate-400 mb-4">
                  Runs the advanced matching query to find an available bed, matching equipment, and an on-duty specialist concurrently.
                </p>
                <div className="flex gap-3 mb-6">
                  <input
                    type="number"
                    value={patientIdToMatch}
                    onChange={(e) => setPatientIdToMatch(e.target.value)}
                    className="bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white w-32"
                    placeholder="Patient ID"
                  />
                  <button
                    onClick={handleFindMatch}
                    className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 rounded-lg text-sm font-medium text-white transition"
                  >
                    Run Match Query
                  </button>
                </div>

                {matchResult && (
                  <div className="p-4 bg-slate-900/90 border border-indigo-700/60 rounded-xl space-y-2 text-xs">
                    <p className="font-bold text-sm text-indigo-400">Match Found for {matchResult.patient_name}</p>
                    <div className="grid grid-cols-2 gap-2 text-slate-300 pt-2">
                      <p>Bed: <span className="text-white font-semibold">{matchResult.bed_number} ({matchResult.bed_type})</span></p>
                      <p>Equipment: <span className="text-white font-semibold">{matchResult.equipment_type}</span></p>
                      <p>Physician: <span className="text-white font-semibold">{matchResult.doctor_name}</span></p>
                      <p>Specialization: <span className="text-white font-semibold">{matchResult.specialization}</span></p>
                    </div>
                  </div>
                )}
              </div>

              {matchResult && (
                <button
                  onClick={handleConfirmAllocation}
                  className="w-full mt-6 py-2.5 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-medium text-white flex items-center justify-center gap-2 transition"
                >
                  <CheckCircle className="w-4 h-4" /> Confirm & Execute Allocation Transaction
                </button>
              )}
            </div>
          </div>
        )}

        {activeTab === 'allocations' && (
          <div>
            <h2 className="text-lg font-semibold mb-4 text-slate-200 flex items-center gap-2">
              <ShieldAlert className="text-amber-400 w-5 h-5" /> Live Active Allocations
            </h2>
            {activeAllocations.length === 0 ? (
              <p className="text-slate-400 text-sm">No active patient allocations currently registered.</p>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {activeAllocations.map((alloc) => (
                  <div key={alloc.allocation_id} className="p-5 rounded-xl bg-slate-800/60 border border-slate-700/80 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between items-start mb-2">
                        <span className="font-bold text-white">{alloc.patient_name}</span>
                        <span className="text-xs px-2 py-0.5 rounded bg-red-950 text-red-400 border border-red-800">
                          Triage {alloc.triage_score}
                        </span>
                      </div>
                      <div className="space-y-1 text-xs text-slate-300">
                        <p>Bed: <span className="font-semibold text-white">{alloc.bed_number}</span></p>
                        <p>Equipment: <span className="font-semibold text-white">{alloc.equipment_type}</span></p>
                        <p>Attending: <span className="font-semibold text-white">{alloc.doctor_name}</span></p>
                      </div>
                    </div>
                    <button
                      onClick={() => handleDischarge(alloc.allocation_id)}
                      className="mt-4 w-full py-2 bg-rose-600/90 hover:bg-rose-600 rounded-lg text-xs font-semibold text-white transition"
                    >
                      Discharge Patient (Bed &rarr; Cleaning)
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}