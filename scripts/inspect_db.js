
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
    process.exit(1);
}

// Function to fetch the Swagger/OpenAPI spec from Supabase (PostgREST)
async function fetchSchema() {
    console.log(`Connecting to ${supabaseUrl}...`);
    try {
        // The PostgREST root endpoint provides the OpenAPI definition
        const response = await fetch(`${supabaseUrl}/rest/v1/?apikey=${supabaseKey}`);

        if (!response.ok) {
            throw new Error(`Failed to fetch schema: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();

        if (!data.definitions) {
            console.log("No definitions found. The API might be empty or permissions restricted.");
            return;
        }

        console.log("--- SCHEMA START ---");
        console.log(JSON.stringify(data.definitions, null, 2));
        console.log("--- SCHEMA END ---");

    } catch (e) {
        console.error("Error inspecting schema:", e.message);
        console.log("Tip: If you have a SERVICE_ROLE_KEY, try using that in .env as SUPABASE_ANON_KEY for this script only.");
    }
}

fetchSchema();
