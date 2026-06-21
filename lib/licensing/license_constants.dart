const String kLicensingBaseUrl =
    'https://bms-licensing.ghx2556tcx.workers.dev';

const Duration kJwtGracePeriod = Duration(days: 7);

// Mirrors TIER_FEATURES in the Worker backend (src/routes/activate.ts).
// Keep in sync when adding features.
const Map<String, Set<String>> kTierFeatures = {
  'free': {'pos', 'inventory', 'customers'},
  'pro': {
    'pos', 'inventory', 'customers',
    'reports', 'grn', 'cheques', 'petty_cash', 'debtors',
  },
  'enterprise': {
    'pos', 'inventory', 'customers',
    'reports', 'grn', 'cheques', 'petty_cash', 'debtors',
    'users', 'api_access', 'multi_branch',
  },
};

// Secure storage key namespace.
const String kLicJwt           = 'bms.lic.jwt';
const String kLicLastValidated = 'bms.lic.last_validated';
const String kLicDeviceId      = 'bms.lic.device_id';
