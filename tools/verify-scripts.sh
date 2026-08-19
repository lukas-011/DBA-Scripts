#!/usr/bin/env bash
# =============================================================================
# Static verification of the SQL toolkit. Runs WITHOUT a database connection.
#
# Catches the classes of defect that are invisible on inspection but fatal at
# runtime: unbalanced parens, trailing commas before FROM, dangling booleans,
# undocumented substitution variables, header claims that no longer match the
# SQL, SQL*Plus state left modified, and broken cross-references.
#
# It does NOT validate column names or view availability - only a real
# database can do that. Green here means "will parse and is documented
# honestly", not "returns correct results".
#
# Usage:  bash tools/verify-scripts.sh
# Exit:   prints findings; "RESULT: no issues found" when clean.
# =============================================================================
cd "$(dirname "$0")/.."

FAIL=0
report() { echo "  [$1] $2"; FAIL=1; }

FILES=$(find . -name "*.sql" -not -path "./.git/*" ! -name "_template.sql" | sed 's|^\./||' | sort)

echo "############ 1. PARENTHESIS BALANCE ############"
for f in $FILES; do
  awk '
    BEGIN{ inblk=0; depth=0 }
    {
      line=$0
      # strip block comments
      while (1) {
        if (inblk) { i=index(line,"*/"); if(i==0){line="";break} else {line=substr(line,i+2); inblk=0} }
        else { i=index(line,"/*"); if(i==0) break; else { pre=substr(line,1,i-1); rest=substr(line,i+2); line=pre; inblk=1; hold=rest; sub(/^/,"",hold); line=pre " " ; inblk=1; line2=rest;
               # handle same-line close
               j=index(line2,"*/"); if(j>0){ line=pre substr(line2,j+2); inblk=0 } else { break } } }
      }
      sub(/--.*$/,"",line)
      # strip single-quoted strings (handles doubled quotes crudely)
      gsub(/'"'"'[^'"'"']*'"'"'/,"",line)
      n=gsub(/\(/,"(",line); m=gsub(/\)/,")",line)
      depth += n - m
    }
    END{ if(depth!=0) printf "DEPTH %d\n", depth }
  ' "$f" | while read -r r; do [ -n "$r" ] && report "PAREN" "$f: unbalanced ($r)"; done
done
echo "  (blank above = all balanced)"

echo
echo "############ 2. TRAILING COMMA BEFORE FROM / CLAUSE ############"
for f in $FILES; do
  awk -v F="$f" '
    { gsub(/[ \t]+$/,"") ; l[NR]=$0 }
    END{
      for(i=1;i<=NR;i++){
        cur=l[i]; nxt=l[i+1]
        if (cur ~ /,[ \t]*$/) {
          # find next non-blank, non-comment line
          j=i+1
          while (j<=NR && (l[j] ~ /^[ \t]*$/ || l[j] ~ /^[ \t]*\/\*/ || l[j] ~ /^[ \t]*--/ || l[j] ~ /^[ \t]*[A-Z ]*\*\//)) j++
          if (l[j] ~ /^[ \t]*(FROM|WHERE|GROUP[ \t]+BY|ORDER[ \t]+BY|HAVING|INTO)\b/) printf "%s:%d: trailing comma before %s\n", F, i, l[j]
        }
      }
    }' "$f"
done
echo "  (blank above = none)"

echo
echo "############ 3. EMPTY WHERE / DANGLING BOOLEAN ############"
for f in $FILES; do
  awk -v F="$f" '
    { l[NR]=$0 }
    END{
      for(i=1;i<=NR;i++){
        if (l[i] ~ /^[ \t]*WHERE[ \t]*$/) {
          j=i+1; while(j<=NR && l[j] ~ /^[ \t]*$/) j++
          if (l[j] ~ /^[ \t]*(AND|OR)\b/) printf "%s:%d: WHERE immediately followed by %s\n", F, i, (l[j] ~ /AND/ ? "AND" : "OR")
        }
        if (l[i] ~ /^[ \t]*(WHERE|AND|OR)[ \t]*$/ && i==NR) printf "%s:%d: file ends on dangling boolean\n", F, i
      }
    }' "$f"
done
echo "  (blank above = none)"

echo
echo "############ 4. STATEMENT TERMINATION ############"
for f in $FILES; do
  # last non-blank, non-comment line should end in ; or / or be a SET/COL directive
  last=$(grep -v '^[ \t]*$' "$f" | grep -v '^[ \t]*--' | tail -1)
  case "$last" in
    *\;|*/) ;;
    SET\ *|set\ *|COL\ *|col\ *) ;;
    *) report "TERM" "$f: last statement line does not terminate: '$last'" ;;
  esac
done
echo "  (blank above = all terminated)"

echo
echo "############ 5. PARAMS HEADER vs SUBSTITUTION VARS USED ############"
for f in $FILES; do
  hdr_end=$(grep -n '=== \*/' "$f" | head -1 | cut -d: -f1)
  [ -z "$hdr_end" ] && hdr_end=$(grep -n '\*/' "$f" | head -1 | cut -d: -f1)
  [ -z "$hdr_end" ] && continue
  header=$(head -n "$hdr_end" "$f")
  body=$(tail -n +$((hdr_end+1)) "$f")
  used=$(echo "$body" | grep -o '&[A-Za-z_][A-Za-z0-9_]*' | sed 's/^&//' | sort -u)
  declared_none=$(echo "$header" | grep -c 'PARAMS   : None')
  for v in $used; do
    echo "$header" | grep -qi "&$v" || report "PARAM" "$f: uses &$v but header does not document it"
  done
  if [ "$declared_none" -gt 0 ] && [ -n "$used" ]; then
    report "PARAM" "$f: header says PARAMS None but body uses: $(echo $used | tr '\n' ' ')"
  fi
done
echo "  (blank above = params consistent)"

echo
echo "############ 6. VIEWS HEADER vs TABLES ACTUALLY QUERIED ############"
for f in $FILES; do
  hdr_end=$(grep -n '=== \*/' "$f" | head -1 | cut -d: -f1)
  [ -z "$hdr_end" ] && continue
  header=$(head -n "$hdr_end" "$f" | tr 'A-Z' 'a-z')
  body=$(tail -n +$((hdr_end+1)) "$f" | tr 'A-Z' 'a-z')
  # tables referenced after FROM or JOIN
  refs=$(echo "$body" | grep -oE '(from|join)[[:space:]]+[a-z_$0-9]+' \
         | sed -E 's/^(from|join)[[:space:]]+//' | grep -vE '^(select|\(|table|dual)$' | sort -u)
  for t in $refs; do
    case "$t" in
      table|dual|select) continue ;;
    esac
    echo "$header" | grep -q -- "$t" || report "VIEWS" "$f: queries '$t' but header VIEWS omits it"
  done
done
echo "  (blank above = views documented)"

echo
echo "############ 7. SQLPLUS STATE LEFT MODIFIED ############"
for f in $FILES; do
  if grep -qi '^SET PAGESIZE 0' "$f" && ! grep -qiE '^SET PAGESIZE [1-9]' "$f"; then
    report "STATE" "$f: sets PAGESIZE 0 but never restores it"
  fi
  if grep -qi '^SET FEEDBACK OFF' "$f" && ! grep -qi '^SET FEEDBACK ON' "$f"; then
    report "STATE" "$f: sets FEEDBACK OFF but never restores it"
  fi
done
echo "  (blank above = state restored)"

echo
echo "############ 8. HEADER FIELD COMPLETENESS ############"
for f in $FILES; do
  case "$f" in login.sql) continue ;; esac
  for k in PURPOSE VIEWS LICENSE RAC PARAMS; do
    grep -q "^   $k " "$f" || report "HDR" "$f: missing $k"
  done
done
echo "  (blank above = headers complete)"

echo
echo "############ 9. RAC FIELD USES A CANONICAL TAG ############"
for f in $FILES; do
  case "$f" in login.sql) continue ;; esac
  tag=$(grep '^   RAC      :' "$f" | sed 's/^   RAC      : //' \
        | grep -oE '^(GV\$ REQUIRED|V\$ CORRECT|PER-INSTANCE|N/A|MIXED)')
  [ -n "$tag" ] || report "RAC" "$f: RAC field does not start with a canonical tag"
done
echo "  (blank above = all tagged)"

echo
echo "############ 9b. RAC PROSE TRUNCATED BY EDITING ############"
for f in $FILES; do
  case "$f" in login.sql) continue ;; esac
  # last line of the RAC block should not end mid-sentence
  lastline=$(awk '/^   RAC      :/{p=1} p&&/^   PARAMS   :/{exit} p{l=$0} END{print l}' "$f")
  echo "$lastline" | grep -qE '(the|a|an|and|but|because|of|to|is|so|for|with|statement.s)[[:space:]]*$' \
    && report "RACPROSE" "$f: RAC block ends mid-sentence: '...$(echo "$lastline" | tail -c 45)'"
done
echo "  (blank above = no truncation)"

echo
echo "############ 10. CROSS-REFERENCES TO OTHER SCRIPTS RESOLVE ############"
for f in $FILES; do
  for ref in $(grep -oE '[a-z-]+/[a-z0-9-]+\.sql' "$f" | sort -u); do
    # skip ORACLE_HOME filesystem paths, which are not repo scripts
    case "$ref" in admin/*) continue ;; esac
    [ -f "$ref" ] || report "XREF" "$f: references missing script '$ref'"
  done
done
echo "  (blank above = all resolve)"

echo
echo "=========================================="
[ $FAIL -eq 0 ] && echo "RESULT: no issues found" || echo "RESULT: issues found above"
