import { env } from '../src/lib/env';
// Importing env uses exactly the same validation as the production server.
console.log('Configuration valid for ' + env.nodeEnv + '; values are not printed.');
