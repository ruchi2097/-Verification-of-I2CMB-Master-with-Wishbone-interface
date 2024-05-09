#Register tests
make cli 	GEN_TRANS_TYPE=i2cmb_invalid			TEST_SEED=random
make cli 	GEN_TRANS_TYPE=i2cmb_read_only 			TEST_SEED=random
make cli 	GEN_TRANS_TYPE=i2cmb_default 		    TEST_SEED=random

#Compulsory tests
make cli 	GEN_TRANS_TYPE=i2cmb_random_read 			TEST_SEED=random
make cli 	GEN_TRANS_TYPE=i2cmb_random_write 			TEST_SEED=random
make cli 	GEN_TRANS_TYPE=i2cmb_random_alternate    	TEST_SEED=random

make merge_coverage
