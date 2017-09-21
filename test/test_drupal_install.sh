#!/bin/sh
#
# Test script using shinit2
#  http://code.google.com/p/shunit2
#
# Template of this file taken from shunit2-2.1.6/examples/mkdir_test.sh
#
# Usage: cd test/ && sh ./test_drupal_install.sh
#
# Unit test for drupal_install.

#-----------------------------------------------------------------------------
# suite tests
#

testHelp()
{
  cwd=`pwd`
  ${testCmd} -d . --help >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse '--help option passes through.' ${rtrn}

  ${testCmd} -d . -h >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue '-h option not recognised' ${rtrn}
  stdoutM=`cat ${stdoutF}` 
  assertEqualsWords  '-h message is wrong:' 'USAGE:' "$stdoutM" 1
  assertEqualsSubstr '-h message is wrong:' 'USAGE:' "$stdoutM" 1
  assertEgrep        '-h message is wrong:' '^ *USAGE' "$stdoutM"
  cd $cwd
}

testMandatoryOption()
{
  ${testCmd} >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse 'Lack of -d option is allowed.' ${rtrn}
  stderrM=`cat ${stderrF}` 
  assertEgrep 'Lack of -d option is allowed.' 'mandatory' "$stderrM"
}

testWrongDir()
{
  ${testCmd} -d /non/existent/directory >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse 'Non-existent directory is allowed:' ${rtrn}
  stderrM=`cat ${stderrF}` 
  assertEgrep 'Message is wrong for Non-existent directory:' 'not exist' "$stderrM"
}

testNewDir()
{
  cwd=`pwd`
  newDir=/`basename $0`_drupinstall_$$
  ${testCmd} -d $newDir >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse 'New directory (forbidden):' ${rtrn}
  stderrM=`cat ${stderrF}`
  assertEgrep 'Message is wrong for new directory (forbidden):' 'not directory' "$stderrM"
  cd $cwd
}

testNewDirForce()
{
  cwd=`pwd`
  newDir=/`basename $0`_drupinstall_$$
  ${testCmd} -f -d $newDir >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse "New directory (forbidden2[$rtrn]: $newDir):" ${rtrn}
  stderrM=`cat ${stderrF}`
  assertEgrep 'Message is wrong for new forbidden directory:' 'not exist.*Creat' "$stderrM"
  assertEgrep 'Message is wrong for new forbidden directory:' 'mkdir' "$stderrM"
  cd $cwd
}

testForbiddenDir()
{
  cwd=`pwd`
  newDir=${testDir}/`basename $0`_testForbiddenDir1.$$
  mkdir -p $newDir
  chmod -x $newDir
  ${testCmd} -f -d $newDir >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse "New directory (permission: $newDir):" ${rtrn}
  stderrM=`cat ${stderrF}`
  assertEgrep 'Message is wrong for new directory (permission):' 'chdir' "$stderrM"
  chmod +x $newDir
  rmdir $newDir
  cd $cwd
}

testDryrunBasic()
{
  cwd=`pwd`
  newDir=${testDir}/`basename $0`_testDrurunBasic.$$
  mkdir -p $newDir
  echo 'pass' | ${testCmd} -n -d $newDir >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "testDryrunBasic():" ${rtrn}
  stdoutM=`cat ${stdoutF}`
  assertEgrep 'testDryrunBasic() 1-1:' 'Dryrun\...' "$stdoutM"
  stderrM=`cat ${stderrF}`
  assertEgrep 'testDryrunBasic() 2-1:' 'Fail.* read.* database' "$stderrM"
  rmdir $newDir
  cd $cwd
}

testCoreVersionOption()
{
  cwd=`pwd`
  BaseDir=`basename $0`_testCoreVersionOption.$$
  newDir=${testDir}/$BaseDir
  mkdir -p $newDir

  # no -c option
  echo 'pass' | ${testCmd} -n -d $newDir >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "testCoreVersionOption() 1:" ${rtrn}
  stdoutM=`cat ${stdoutF} | grep 'drush dl' | head -n 1 | sed 's/.*=[^ ]*//'`" X"
  assertEqualsWords "X"           "$stdoutM" '1' 

  # -c 10
  echo 'pass' | ${testCmd} -n -d $newDir -c 10 >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "testCoreVersionOption() 2:" ${rtrn}
  stdoutM=`cat ${stdoutF} | grep 'drush dl' | head -n 1 | sed 's/.*=[^ ]*//'`
  assertEqualsWords "drupal-10.x" "$stdoutM" '1'

  # -c drupal-8.0
  echo 'pass' | ${testCmd} -n -d $newDir -c drupal-8.0 >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "testCoreVersionOption() 3:" ${rtrn}
  stdoutM=`cat ${stdoutF} | grep 'drush dl' | head -n 1 | sed 's/.*=[^ ]*//'`
  assertEqualsWords "drupal-8.0"  "$stdoutM" '1'

  rmdir $newDir
}

testDryrunAllOpts()
{
  cwd=`pwd`
  newDir=${testDir}/`basename $0`_testDrurunAllOpts.$$
  mkdir -p $newDir
  echo 'pass' | ${testCmd} -n -d $newDir -u webmaster -m web@xxx.com -q testmydb -t 'Test Title 1' -s 'Test Slogan 2' -l 'fr' >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "testDryrunAllOpts():" ${rtrn}
  stdoutM=`cat ${stdoutF}`
  assertEgrep 'testDryrunAllOpts() 1-01:' 'Dryrun\...' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-02:' 'Site.*Name.*Test Title 1' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-03:' 'Site.*Slogan.*Test Slogan 2' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-04:' 'Site.*Locale.*fr' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-05:' 'Admin.*Username.*webmaster' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-06:' 'Admin.*Email.*web@xxx.com' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-07:' 'Database.*Name.*testmydb' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-08:' 'Database.*User.*testmydb' "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-09:' 'drush .*drupal-project-rename='`basename $newDir` "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-10:' 'drush .*destination='`dirname $newDir` "$stdoutM"
  assertEgrep 'testDryrunAllOpts() 1-11:' 'drush *site-install.*db-url=.*\*\*\*\*' "$stdoutM"	# Password not displayed.

  stderrM=`cat ${stderrF}`
  assertEgrep 'testDryrunAllOpts() 2-1:' 'Fail.* read.* database' "$stderrM"
  rmdir $newDir
  cd $cwd
}


testCurdir()
{
  cwd=`pwd`

  cd /tmp
  echo 'pass' | ${testCmd} -d /tmp >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse "testCurdir() 1:" ${rtrn}
  stderrM=`cat ${stderrF}`
  assertEgrep 'testCurdir() 2-1:' 'instal.*directory' "$stderrM"

  echo 'pass' | ${testCmd} -d . >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertFalse "testCurdir() 3:" ${rtrn}
  stderrM=`cat ${stderrF}`
  assertEgrep 'testCurdir() 4-1:' 'instal.*directory' "$stderrM"

  cd $cwd
}


# testMissingDirectoryCreation()
# {
#   ${testCmd} "${testDir}" >${stdoutF} 2>${stderrF}
#   rtrn=$?
#   th_assertTrueWithNoOutput ${rtrn} "${stdoutF}" "${stderrF}"
# 
#   assertTrue 'directory missing' "[ -d '${testDir}' ]"
# }
# 
# testExistingDirectoryCreationFails()
# {
#   # create a directory to test against
#   ${testCmd} "${testDir}"
# 
#   # test for expected failure while trying to create directory that exists
#   ${testCmd} "${testDir}" >${stdoutF} 2>${stderrF}
#   rtrn=$?
#   assertFalse 'expecting return code of 1 (false)' ${rtrn}
#   assertNull 'unexpected output to stdout' "`cat ${stdoutF}`"
#   assertNotNull 'expected error message to stderr' "`cat ${stderrF}`"
# 
#   assertTrue 'directory missing' "[ -d '${testDir}' ]"
# }
# 
# testRecursiveDirectoryCreation()
# {
#   testDir2="${testDir}/test2"
# 
#   ${testCmd} -p "${testDir2}" >${stdoutF} 2>${stderrF}
#   rtrn=$?
#   th_assertTrueWithNoOutput ${rtrn} "${stdoutF}" "${stderrF}"
# 
#   assertTrue 'first directory missing' "[ -d '${testDir}' ]"
#   assertTrue 'second directory missing' "[ -d '${testDir2}' ]"
# }

#-----------------------------------------------------------------------------
# suite functions
#

# Assert that two pair of words in given position(s) are equal to one another.
#
# Args:
#   message: string: failure message [optional]
#   expected: string: expected value, separated with a single space
#   actual: string: actual value (original string)
#   positions: string: positional parameters, separated with ',', eg., 3,4,5
# Returns:
#   integer: success (TRUE/FALSE/ERROR constant)
# NOTE:
#   Only the first non-empty line counts (empty lines are ignored).
# Examples:
#   assertEqualsWords("is a", "This is  a pen.", '2,3')	# => 0 (TRUE)
#   assertEqualsWords("That not.", " \n That was not.", '1,3')	# => 0 (TRUE)
assertEqualsWords()
{
  ${_SHUNIT_LINENO_}
  if [ $# -lt 3 -o $# -gt 4 ]; then
    _shunit_error "assertEqualsWords() requires three or four arguments; $# given"
    return ${SHUNIT_ERROR}
  fi
  _shunit_shouldSkip && return ${SHUNIT_TRUE}

  shunit_message_=${__shunit_lineno}
  if [ $# -eq 4 ]; then
    shunit_message_="${shunit_message_}$1"
    shift
  fi
  shunit_expected_=$1
  shunit_actual_orig_=$2
  shunit_positions_=$3

  shunit_posStrTmp_=`echo $shunit_positions_ | sed -e 's/, */,$/g' -e 's/^/$/'`	# '$1,$3,$4' etc
  shunit_actual_2compare_=`echo "$shunit_actual_orig_" | awk '(! /^\ *$/){print '$shunit_posStrTmp_'}' | head -n 1`	# Only the first non-empty line counts.

  shunit_return=${SHUNIT_TRUE}
  if [ "${shunit_expected_}" = "${shunit_actual_2compare_}" ]; then
    _shunit_assertPass
  else
    failNotEquals "${shunit_message_}" "${shunit_expected_}" "${shunit_actual_orig_}"
    shunit_return=${SHUNIT_FALSE}
  fi

  unset shunit_message_ shunit_positions_ shunit_expected_ shunit_actual_orig_ shunit_posStrTmp_ shunit_actual_2compare_
  return ${shunit_return}
}
_ASSERT_EQUALSWORDS_='eval assertEqualsWords --lineno "${LINENO:-}"'


# Assert that substrings in given position(s) are equal to one another.
#
# Args:
#   message: string: failure message [optional]
#   expected: string: expected value, separated with a single space
#   actual: string: actual value (original string)
#   start-position: integer: positional parameters (the first character is 1.)
# Note:
#   Only the first line, including an empty line, counts (the rest is ignored).
# Returns:
#   integer: success (TRUE/FALSE/ERROR constant)
# Examples:
#   assertEqualsSubstr("is   a", "This is  a pen.", 6)	# => 0 (TRUE)
#   assertEqualsSubstr("That ", " That was not", 2)	# => 0 (TRUE)
assertEqualsSubstr()
{
  ${_SHUNIT_LINENO_}
  if [ $# -lt 3 -o $# -gt 4 ]; then
    _shunit_error "assertEqualsSubstr() requires three or four arguments; $# given"
    return ${SHUNIT_ERROR}
  fi
  _shunit_shouldSkip && return ${SHUNIT_TRUE}

  shunit_message_=${__shunit_lineno}
  if [ $# -eq 4 ]; then
    shunit_message_="${shunit_message_}$1"
    shift
  fi
  shunit_expected_=$1
  shunit_actual_orig_=$2
  shunit_position_=$3

  shunit_nchar_=`/bin/echo -n "$shunit_expected_" | wc -c`	# (built-in) echo may not recognise the -n option.
  shunit_fpos_=`expr $shunit_position_ + $shunit_nchar_ - 1`
  shunit_actual_2compare_=`echo "$shunit_actual_orig_" | cut -c${shunit_position_}-${shunit_fpos_} | head -n 1`

  shunit_return=${SHUNIT_TRUE}
  if [ "${shunit_expected_}" = "${shunit_actual_2compare_}" ]; then
    _shunit_assertPass
  else
    # failNotEquals "${shunit_message_}" "${shunit_expected_}" "${shunit_actual_orig_}"
    echo 'In "'${shunit_actual_orig_}'", ' >&2
    failNotEquals "${shunit_message_}" "${shunit_expected_}" "${shunit_actual_2compare_}"
    shunit_return=${SHUNIT_FALSE}
  fi

  unset shunit_message_ shunit_position_ shunit_expected_ shunit_actual_orig_ shunit_nchar_ shunit_fpos_ shunit_actual_2compare_
  return ${shunit_return}
}
_ASSERT_EQUALSSUBSTR_='eval assertEqualsSubstr --lineno "${LINENO:-}"'


# Assert that the string is true with egrep() for the given regular expression.
#
# Args:
#   message: string: failure message [optional]
#   pattern: string: (extended) regular-expression in egrep style
#   actual: string: actual value (original string)
# Returns:
#   integer: success (TRUE/FALSE/ERROR constant)
# Examples:
#   assertEgrep('is +a', "This is  a pen.")	# => 0 (TRUE)
#   assertEgrep('(is|was)', " That was not")	# => 0 (TRUE)
assertEgrep()
{
  ${_SHUNIT_LINENO_}
  if [ $# -lt 2 -o $# -gt 3 ]; then
    _shunit_error "assertEgrep() requires two or three arguments; $# given"
    return ${SHUNIT_ERROR}
  fi
  _shunit_shouldSkip && return ${SHUNIT_TRUE}

  shunit_message_=${__shunit_lineno}
  if [ $# -eq 3 ]; then
    shunit_message_="${shunit_message_}$1"
    shift
  fi
  shunit_pattern_=$1
  shunit_actual_=$2

  echo "$shunit_actual_" | egrep "$shunit_pattern_" >/dev/null 2>&1
  shunit_rtrnegrep=$?
  assertTrue "$shunit_message_ for egrep('$shunit_pattern_') with \"$shunit_actual_\"" ${shunit_rtrnegrep}

  unset shunit_message_ shunit_pattern_ shunit_actual_ shunit_rtrnegrep
  return ${shunit_return}
}
_ASSERT_EGREP_='eval assertEgrep --lineno "${LINENO:-}"'


# th_assertTrueWithNoOutput_unique()
# {
#   th_return_=$1
#   th_stdout_=$2
#   th_stderr_=$3
# 
#   assertFalse 'unexpected output to STDOUT' "[ -s '${th_stdout_}' ]"
#   assertFalse 'unexpected output to STDERR' "[ -s '${th_stderr_}' ]"
# 
#   unset th_return_ th_stdout_ th_stderr_
# }

oneTimeSetUp()		# setUp() may be better??
{
  outputDir="${SHUNIT_TMPDIR}/output"
  [ ! -e "${outputDir}" ] && mkdir "${outputDir}"
  stdoutF="${outputDir}/stdout"
  stderrF="${outputDir}/stderr"

  testCmd='sh -l ../drupal_install.sh'  # save command name in variable to make future changes easy
  testDir="${SHUNIT_TMPDIR}/drupal_install"
  mkdir -p $testDir
}

tearDown()
{
  rm -fr "${testDir}"
  rm -f "${stdoutF}" "${stderrF}"
}

# load and run shUnit2
[ -n "${ZSH_VERSION:-}" ] && SHUNIT_PARENT=$0
. ${HOME}/lib/sh/shunit2_test_helpers
. ${HOME}/lib/sh/shunit2
