col inst_id for 99
col object_name for a30
col object_type for a20
col owner for a15

SELECT
    lo.inst_id,
    lo.session_id AS sid,
    do.owner,
    do.object_name,
    do.object_type
FROM
    gv$locked_object lo
JOIN
    dba_objects do
    ON lo.object_id = do.object_id
WHERE
    lo.session_id = &blocker_sid
ORDER BY
    lo.inst_id, lo.session_id;