#!/usr/bin/env bash
# Reproduces the verification suite for every endpoint.
#
# Read-only by default. Pass --write to also exercise the two endpoints that
# modify data (enrolment and grading); see WRITE TESTS below for what changes.
#
#   ./scripts/smoke-test.sh
#   ./scripts/smoke-test.sh --write
#
# Requires the server to be running and the seed password to be Password123!.

set -u

BASE="${BASE_URL:-http://localhost:3000}"
PASSWORD="${SEED_PASSWORD:-Password123!}"
RUN_WRITES=false
[[ "${1:-}" == "--write" ]] && RUN_WRITES=true

pass=0
fail=0

token() {
  curl -s -X POST "$BASE/api/auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"$1\",\"password\":\"$PASSWORD\"}" |
    node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{console.log(JSON.parse(d).token)}catch{console.log('')}})"
}

# check <label> <expected-status> <curl args...>
check() {
  local label="$1" expected="$2"
  shift 2
  local actual
  actual=$(curl -s -o /dev/null -w '%{http_code}' "$@")
  if [[ "$actual" == "$expected" ]]; then
    printf '  \033[32mPASS\033[0m  %-46s %s\n' "$label" "$actual"
    pass=$((pass + 1))
  else
    printf '  \033[31mFAIL\033[0m  %-46s got %s, expected %s\n' "$label" "$actual" "$expected"
    fail=$((fail + 1))
  fi
}

echo "Base URL: $BASE"
S001=$(token S001); L001=$(token L001); L002=$(token L002); A001=$(token A001)

if [[ -z "$S001" ]]; then
  echo "Could not log in as S001. Is the server running, and has sql/02_seed_password_hashes.sql been applied?"
  exit 1
fi

echo
echo "AUTH"
check "login S001"                  200 -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d "{\"username\":\"S001\",\"password\":\"$PASSWORD\"}"
check "login wrong password"        401 -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d '{"username":"S001","password":"wrong"}'
check "login unknown user"          401 -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d "{\"username\":\"NOPE\",\"password\":\"$PASSWORD\"}"
check "login missing field"         400 -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d '{"username":"S001"}'
check "me with token"               200 "$BASE/api/auth/me" -H "Authorization: Bearer $S001"
check "me without token"            401 "$BASE/api/auth/me"
check "me with garbage token"       401 "$BASE/api/auth/me" -H "Authorization: Bearer not.a.token"

echo
echo "TRANSCRIPT"
check "S001 reads own"              200 "$BASE/api/students/S001/transcript" -H "Authorization: Bearer $S001"
check "S001 reads S002 (blocked)"   403 "$BASE/api/students/S002/transcript" -H "Authorization: Bearer $S001"
check "A001 reads any"              200 "$BASE/api/students/S001/transcript" -H "Authorization: Bearer $A001"
check "L001 blocked"                403 "$BASE/api/students/S001/transcript" -H "Authorization: Bearer $L001"
check "unknown student"             404 "$BASE/api/students/S999/transcript" -H "Authorization: Bearer $A001"
check "no token"                    401 "$BASE/api/students/S001/transcript"

echo
echo "STUDENT TIMETABLE"
check "S001 reads own"              200 "$BASE/api/students/S001/timetable" -H "Authorization: Bearer $S001"
check "S001 reads S002 (blocked)"   403 "$BASE/api/students/S002/timetable" -H "Authorization: Bearer $S001"
check "A001 reads any"              200 "$BASE/api/students/S001/timetable" -H "Authorization: Bearer $A001"
check "L001 blocked"                403 "$BASE/api/students/S001/timetable" -H "Authorization: Bearer $L001"
check "unknown student"             404 "$BASE/api/students/S999/timetable" -H "Authorization: Bearer $A001"

echo
echo "LECTURER TIMETABLE"
check "L001 reads own"              200 "$BASE/api/lecturers/L001/timetable" -H "Authorization: Bearer $L001"
check "L001 reads L002 (blocked)"   403 "$BASE/api/lecturers/L002/timetable" -H "Authorization: Bearer $L001"
check "A001 reads any"              200 "$BASE/api/lecturers/L001/timetable" -H "Authorization: Bearer $A001"
check "S001 blocked"                403 "$BASE/api/lecturers/L001/timetable" -H "Authorization: Bearer $S001"
check "unknown lecturer"            404 "$BASE/api/lecturers/L999/timetable" -H "Authorization: Bearer $A001"

echo
echo "COURSE ROSTER"
check "L001 reads own course"       200 "$BASE/api/courses/C001/roster" -H "Authorization: Bearer $L001"
check "L001 reads L002's course"    403 "$BASE/api/courses/C002/roster" -H "Authorization: Bearer $L001"
check "enrolled student reads"      200 "$BASE/api/courses/C001/roster" -H "Authorization: Bearer $S001"
check "student not enrolled"        403 "$BASE/api/courses/C002/roster" -H "Authorization: Bearer $S001"
check "A001 reads any"              200 "$BASE/api/courses/C002/roster" -H "Authorization: Bearer $A001"
check "unknown course"              404 "$BASE/api/courses/C999/roster" -H "Authorization: Bearer $A001"
check "no token"                    401 "$BASE/api/courses/C001/roster"

echo
echo "ATTENDANCE SUMMARY"
check "S001 reads own"              200 "$BASE/api/students/S001/attendance" -H "Authorization: Bearer $S001"
check "S001 reads S002 (blocked)"   403 "$BASE/api/students/S002/attendance" -H "Authorization: Bearer $S001"
check "L001 blocked"                403 "$BASE/api/students/S001/attendance" -H "Authorization: Bearer $L001"
check "A001 reads any"              200 "$BASE/api/students/S001/attendance" -H "Authorization: Bearer $A001"
check "unknown student"             404 "$BASE/api/students/S999/attendance" -H "Authorization: Bearer $A001"

echo
echo "ASSESSMENT STATUS"
check "S001 reads own"              200 "$BASE/api/students/S001/assessments" -H "Authorization: Bearer $S001"
check "S001 reads S002 (blocked)"   403 "$BASE/api/students/S002/assessments" -H "Authorization: Bearer $S001"
check "A001 reads any"              200 "$BASE/api/students/S001/assessments" -H "Authorization: Bearer $A001"
check "unknown student"             404 "$BASE/api/students/S999/assessments" -H "Authorization: Bearer $A001"

echo
echo "LECTURER LOAD"
check "L001 reads own"              200 "$BASE/api/lecturers/L001/load" -H "Authorization: Bearer $L001"
check "L001 reads L002 (blocked)"   403 "$BASE/api/lecturers/L002/load" -H "Authorization: Bearer $L001"
check "S001 blocked"                403 "$BASE/api/lecturers/L001/load" -H "Authorization: Bearer $S001"
check "unknown lecturer"            404 "$BASE/api/lecturers/L999/load" -H "Authorization: Bearer $A001"
check "admin all-lecturer overview" 200 "$BASE/api/lecturers/load" -H "Authorization: Bearer $A001"
check "lecturer denied overview"    403 "$BASE/api/lecturers/load" -H "Authorization: Bearer $L001"
check "student denied overview"     403 "$BASE/api/lecturers/load" -H "Authorization: Bearer $S001"

echo
echo "ENROLMENT (authorization only - no data written)"
check "S001 blocked"                403 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $S001"  -H 'Content-Type: application/json' -d '{"courseId":"C006"}'
check "L001 blocked"                403 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $L001"  -H 'Content-Type: application/json' -d '{"courseId":"C006"}'
check "no token"                    401 -X POST "$BASE/api/students/S001/enrollments" -H 'Content-Type: application/json' -d '{"courseId":"C006"}'
check "missing courseId"            400 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $A001"  -H 'Content-Type: application/json' -d '{}'
check "unknown student"             404 -X POST "$BASE/api/students/S999/enrollments" -H "Authorization: Bearer $A001"  -H 'Content-Type: application/json' -d '{"courseId":"C005"}'
check "unknown course"              404 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $A001"  -H 'Content-Type: application/json' -d '{"courseId":"C999"}'

echo
echo "USER CREATION (rejections only - no data written)"
NEWUSER='{"userId":"U990","studentId":"S990","email":"probe@lms.edu","password":"TestPass123!","firstName":"A","lastName":"B"}'
check "student cannot create"       403 -X POST "$BASE/api/students"  -H "Authorization: Bearer $S001" -H 'Content-Type: application/json' -d "$NEWUSER"
check "lecturer cannot create"      403 -X POST "$BASE/api/students"  -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d "$NEWUSER"
check "lecturer cannot create admin" 403 -X POST "$BASE/api/admins"   -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"userId":"U991","adminId":"A991","email":"p2@lms.edu","password":"TestPass123!","firstName":"A","lastName":"B"}'
check "no token"                    401 -X POST "$BASE/api/students"  -H 'Content-Type: application/json' -d "$NEWUSER"
check "missing fields"              400 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U992"}'
check "short password"              400 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U993","studentId":"S993","email":"p3@lms.edu","password":"short","firstName":"A","lastName":"B"}'
check "malformed email"             400 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U994","studentId":"S994","email":"notanemail","password":"TestPass123!","firstName":"A","lastName":"B"}'
check "bad date format"             400 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U995","studentId":"S995","email":"p4@lms.edu","password":"TestPass123!","firstName":"A","lastName":"B","dateOfBirth":"15/03/2004"}'
check "duplicate studentId"         409 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U996","studentId":"S001","email":"p5@lms.edu","password":"TestPass123!","firstName":"A","lastName":"B"}'
check "duplicate email"             409 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U997","studentId":"S997","email":"ama.owusu@lms.edu","password":"TestPass123!","firstName":"A","lastName":"B"}'

echo
echo "GRADING (rejections only - no data written)"
check "L001 grades L002's course"   403 -X PUT "$BASE/api/submissions/SUB002/grade" -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"score":50}'
check "student blocked"             403 -X PUT "$BASE/api/submissions/SUB001/grade" -H "Authorization: Bearer $S001" -H 'Content-Type: application/json' -d '{"score":100}'
check "score above MaxScore"        400 -X PUT "$BASE/api/submissions/SUB003/grade" -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"score":999}'
check "negative score"              400 -X PUT "$BASE/api/submissions/SUB001/grade" -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"score":-50}'
check "non-numeric score"           400 -X PUT "$BASE/api/submissions/SUB001/grade" -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"score":"abc"}'
check "unknown submission"          404 -X PUT "$BASE/api/submissions/SUB999/grade" -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"score":50}'
check "no token"                    401 -X PUT "$BASE/api/submissions/SUB001/grade" -H 'Content-Type: application/json' -d '{"score":50}'

if $RUN_WRITES; then
  echo
  echo "WRITE TESTS - these modify the database"
  echo "  enrols S001 in C006, re-grades SUB001 to 95 then back to 92, and"
  echo "  creates users S990 / L990 / A990. The re-grade leaves rows in"
  echo "  SUBMISSION_AUDIT_LOG. Cleanup SQL is in the README."
  check "admin enrols S001 in C006"  201 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"courseId":"C006"}'
  check "duplicate enrolment"        409 -X POST "$BASE/api/students/S001/enrollments" -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"courseId":"C006"}'
  check "L001 grades own course"     200 -X PUT "$BASE/api/submissions/SUB001/grade" -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"score":95}'
  check "restore SUB001 to 92"       200 -X PUT "$BASE/api/submissions/SUB001/grade" -H "Authorization: Bearer $L001" -H 'Content-Type: application/json' -d '{"score":92}'
  check "create student S990"        201 -X POST "$BASE/api/students"  -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U990","studentId":"S990","email":"probe.student@lms.edu","password":"TestPass123!","firstName":"Probe","lastName":"Student","dateOfBirth":"2004-01-01"}'
  check "created user can log in"    200 -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d '{"username":"S990","password":"TestPass123!"}'
  check "create lecturer L990"       201 -X POST "$BASE/api/lecturers" -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U991","lecturerId":"L990","email":"probe.lecturer@lms.edu","password":"TestPass123!","firstName":"Probe","lastName":"Lecturer"}'
  check "create admin A990"          201 -X POST "$BASE/api/admins"    -H "Authorization: Bearer $A001" -H 'Content-Type: application/json' -d '{"userId":"U992","adminId":"A990","email":"probe.admin@lms.edu","password":"TestPass123!","firstName":"Probe","lastName":"Admin"}'
fi

echo
echo "  $pass passed, $fail failed"
[[ $fail -eq 0 ]] || exit 1
