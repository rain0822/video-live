SELECT
    p.policy_id,
    pt.name policy_type_name,
    t.name term_name,
    csc.name contract_sales_channel_name,
    TO_CHAR(vpip.POLICY_EFFECTIVE_DT, 'dd-MM-yyyy') purchase_start_date,
    TO_CHAR(vpip.POLICY_EXP_DT, 'dd-MM-yyyy') purchase_end_date,
    vpip.product_model_no
FROM
    policy p,
    (select
        * 
    from
        v_policy_items_product ) vpip,
        term t,
        policy_type pt,
        contract_sales_channel csc
WHERE
    p.policy_id = vpip.policy_id
    AND vpip.term_id = t.term_id
    AND vpip.policy_type_id = pt.policy_type_id
    AND vpip.contract_sales_channel_id = csc.contract_sales_channel_id
ORDER BY
    pt.name;
    
    
    
SELECT
    distinct p1.serial_num       
FROM
    V_POLICY_ITEM_PACKAGE_XREF p1             
WHERE
    p1.policy_id = :policy_id 
    and p1.package_id in (
        SELECT
            package_id                 
        FROM
            (SELECT
                pack_si.package_id,
                COUNT (DISTINCT si.serialized_item_id)                             OVER (PARTITION 
            BY
                pack_si.package_id)                               no_of_si_pack_match,
                si.serial_num,
                no_of_pol_items,
                no_of_si_pack,
                policy_id                   
            FROM
                (                          SELECT
                    pol.policy_id,
                    prod.product_id,
                    no_of_pol_items                          
                FROM
                    policy_type pol_typ                            
                JOIN
                    policy pol USING (policy_type_id)                            
                JOIN
                    (
                        SELECT
                            DISTINCT                               t1.policy_id,
                            t1.policy_item_id,
                            COUNT (DISTINCT policy_item_id)                               OVER (PARTITION 
                        BY
                            policy_id)                                 no_of_pol_items                             
                        FROM
                            policy_coverage t1
                    ) pol_cov                              
                        ON (
                            pol_cov.policy_id = pol.policy_id
                        )                            
                JOIN
                    policy_item_selection pol_sel USING (policy_item_id)                            
                JOIN
                    product prod                              
                        ON pol_sel.POLICY_ITEM_SELECTION_VALUE = prod.product_id                        
                    ) pol                     
            JOIN
                serialized_item si 
                    ON pol.product_id = si.product_id                     
            JOIN
                (
                    SELECT
                        t1.*,
                        COUNT (DISTINCT serialized_item_id)                             OVER (PARTITION 
                    BY
                        package_id)                               no_of_si_pack                           
                    FROM
                        package_si_xref t1                           
                ) pack_si                       
                    ON si.serialized_item_id = pack_si.serialized_item_id                       
            where
                policy_id = :policy_id
            )                   
        WHERE
            no_of_pol_items = no_of_si_pack       
            and no_of_si_pack = no_of_si_pack_match                 );