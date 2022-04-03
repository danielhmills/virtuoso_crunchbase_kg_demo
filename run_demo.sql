--Script for creating Crunchbase knowledge graph

-- Procedure for confirming if tables already exist
DROP PROCEDURE table_check;
CREATE PROCEDURE table_check(IN tbl VARCHAR){
    DECLARE tbl_name, q VARCHAR;
    DECLARE state, msg, descs, rows ANY;
    state := '00000';
    tbl_name := tbl;
    q := sprintf('SELECT TOP 1 * FROM %s',tbl_name);
    EXEC(q, state,
    msg, vector (), 1, descs, rows);
    IF(state = '00000'){
        RETURN 1;
    }
    IF(state <> '00000'){
        RETURN 0;
    }
};

--Procedure for creating directory for CSVs, downloading CSVs, and attaching CSVs to virtual tables
DROP PROCEDURE openlink_crunchbase_demo_gen;
CREATE PROCEDURE openlink_crunchbase_demo_gen(){
    DECLARE files ANY;
    DECLARE cb_dir, loc, resp, tb_name, csv_name VARCHAR;
    
    -- Create Directory
    cb_dir := 'openlink_crunchbase_kb_demo';
    file_mkdir(cb_dir);

    -- Download, save, and attach CSVs
    files := vector('acquisitions',
                    'category_groups',
                    'degrees',
                    'event_appearances',
                    'events',
                    'funding_rounds',
                    'funds', 
                    'investment_partners',
                    'investments',
                    'investors',
                    'ipos',
                    'jobs',
                    'org_parents',
                    'organization_descriptions',
                    'organizations',
                    'people_descriptions',
                    'people');  
    FOREACH (VARCHAR X IN files) DO{
        loc := sprintf('https://raw.githubusercontent.com/danielhmills/virtuoso_crunchbase_kg_demo/main/data/%s.csv',X);
        resp := http_get(loc);
        string_to_file(sprintf('%s/%s.csv',cb_dir,X), resp, 0);
        tb_name := sprintf('crunchbase.demo.%s',X);
        csv_name := concat(cb_dir,'/',X,'.csv');
        if(table_check(tb_name) = 1){
            exec(sprintf('DROP TABLE %s',tb_name));
        };
        ATTACH_FROM_CSV(tb_name,csv_name,',','\n',null,1,vector(1));
    }
    RETURN 1;
};

SELECT openlink_crunchbase_demo_gen();
