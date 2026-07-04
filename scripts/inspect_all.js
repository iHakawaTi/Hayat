const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

async function inspectAll() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
        console.error('Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.');
        process.exit(1);
    }

    console.log(`Checking ${supabaseUrl}...`);

    try {
        // Try to fetch the OpenAPI specification from the PostgREST root
        // This is the standard way to discover exposed tables in Supabase
        const response = await fetch(`${supabaseUrl}/rest/v1/?apikey=${supabaseKey}`, {
            headers: {
                'apikey': supabaseKey,
                'Authorization': `Bearer ${supabaseKey}`
            }
        });

        if (!response.ok) {
            console.error(`Failed to fetch API root: ${response.status} ${response.statusText}`);
            const text = await response.text();
            console.error('Body:', text);
            return;
        }

        // The root response implies the table structure if we look at the 'definitions' or 'paths'
        // in the returned Swagger/OpenAPI JSON.
        const schema = await response.json();

        console.log('--- Database Discovery (Public Schema) ---');

        // Check if it's swagger/openapi format
        if (schema.definitions) {
            const tables = Object.keys(schema.definitions);
            if (tables.length === 0) {
                console.log('No public tables found in the API definition.');
            } else {
                console.log(`Found ${tables.length} tables:`);
                tables.forEach(t => console.log(`- ${t}`));

                // Detailed dump of columns for found tables
                console.log('\n--- Table Details ---');
                for (const table of tables) {
                    console.log(`\nTable: ${table}`);
                    const def = schema.definitions[table];
                    if (def && def.properties) {
                        Object.entries(def.properties).forEach(([colName, colDef]) => {
                            console.log(`  - ${colName} (${colDef.type || colDef.format})`);
                        });
                    }
                }
            }
        } else {
            console.log('Response was not in expected OpenAPI format. Raw keys:', Object.keys(schema));
        }

    } catch (err) {
        console.error('Error during inspection:', err);
    }
}

inspectAll();
