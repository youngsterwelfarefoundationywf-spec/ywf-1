/// <reference types="vite/client" />
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://enifukjimtnvkwzmervg.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuaWZ1a2ppbXRudmt3em1lcnZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MDA4MDEsImV4cCI6MjA5NDE3NjgwMX0.2Fusm5XWViUCToQhSCAiZeyV28mESB-ZnhtD7j3zFGQ';

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase credentials missing. Please check your environment variables.');
}

export const supabase = createClient(
  supabaseUrl || '',
  supabaseAnonKey || ''
);
