#include <unity.h>

void test_unity(void) {
	TEST_ASSERT_GREATER_THAN_MESSAGE(2, 4, "failed");
}

void main(void)
{
	(void)unity_main();
}
