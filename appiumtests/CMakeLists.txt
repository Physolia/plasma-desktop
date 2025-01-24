# SPDX-FileCopyrightText: 2023 Fushan Wen <qydwhotmail@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause

if(NOT BUILD_TESTING OR NOT CMAKE_SYSTEM_NAME MATCHES "Linux")
    return()
endif()
find_package(SeleniumWebDriverATSPI)
set_package_properties(SeleniumWebDriverATSPI PROPERTIES
    DESCRIPTION "Server component for selenium tests using Linux accessibility infrastructure"
    PURPOSE "Needed for GUI tests"
    URL "https://invent.kde.org/sdk/selenium-webdriver-at-spi"
    TYPE OPTIONAL
)
if(NOT SeleniumWebDriverATSPI_FOUND AND NOT DEFINED ENV{KDECI_BUILD})
    return()
endif()

add_subdirectory(inputsynth)

add_test(
    NAME desktoptest
    COMMAND selenium-webdriver-at-spi-run ${CMAKE_CURRENT_SOURCE_DIR}/desktoptest.py --failfast
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
execute_process(COMMAND ${CMAKE_C_COMPILER} -print-file-name=libasan.so OUTPUT_VARIABLE LIBASAN_PATH ECHO_OUTPUT_VARIABLE OUTPUT_STRIP_TRAILING_WHITESPACE)
set_tests_properties(desktoptest PROPERTIES TIMEOUT 300 ENVIRONMENT "LD_PRELOAD=${LIBASAN_PATH};CMAKE_BINARY_DIR=${CMAKE_BINARY_DIR};KACTIVITYMANAGERD_PATH=${KDE_INSTALL_FULL_LIBEXECDIR}/kactivitymanagerd")

add_test(
    NAME kcm_plasmasearch_test
    COMMAND selenium-webdriver-at-spi-run ${CMAKE_CURRENT_SOURCE_DIR}/kcm_plasmasearch_test.py
)
set_tests_properties(kcm_plasmasearch_test PROPERTIES TIMEOUT 120)
