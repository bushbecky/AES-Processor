#
# Makefile for AES Encryptor/Decryptor Project
# ECE 571 SP2016
#

#MODE ?= standard
MODE ?= puresim
#MODE ?= veloce

KEY_WIDTH ?= 128
ifeq ($(KEY_WIDTH),128)
    KEY_WIDTH_MACRO := AES_128
else ifeq ($(KEY_WIDTH),192)
    KEY_WIDTH_MACRO := AES_192
else ifeq ($(KEY_WIDTH),256)
    KEY_WIDTH_MACRO := AES_256
else
    $(error "Invalid key width specified")
endif

SRC_DIR ?= src
TST_DIR ?= test/bench
HVL_DIR ?= test/hvl

ERROR_REGEX ?= "Errors: [1-9]\|Warnings: [1-9]"
BAR_START_LINE = "\n\n\n**********************************************"
SIM_FAIL = "\n***  Simulation Error/Warning. Check Log.  ***\n"
SIM_PASS = "\n*** Simulation completed without failures. ***\n"
BAR_END_LINE = "**********************************************\n\n\n"

COMPILE_CMD = vlog
COMPILE_FLAGS = -mfcu 
COMPILE_LOG = compile_log.log

SIMULATE_CMD = vsim

ifeq ($(MODE),standard)
SIMULATE_FLAGS = -c  -do "run -all"
else
SIMULATE_FLAGS = -c  -do "run -all" +tbxrun+"$(QUESTA_RUNTIME_OPTS)"
SIMULATE_MANAGER = TbxSvManager 
endif

SIM_LOG ?= sim_log.log

SRC_FILES = \
	$(SRC_DIR)/AESDefinitions.sv \
	$(SRC_DIR)/*.sv

TST_FILES = \
	$(TST_DIR)/AESTestDefinitions.sv \
	$(TST_DIR)/*.sv

HVL_FILES = $(HVL_DIR)/EncoderDecoderTestBench.sv

SIM_TARGETS = sim_subbytes sim_shiftrows sim_mixcolumns sim_addroundkey \
              sim_round sim_buffered_round sim_expandkey sim_encoder_decoder

define check_sim
	@printf $(BAR_START_LINE);	\
	grep $(ERROR_REGEX) $(SIM_LOG) > /dev/null;  \
               if [ $$? -eq 0 ]; then printf $(SIM_FAIL); else printf $(SIM_PASS); fi; \
	printf $(BAR_END_LINE)
endef

compile:

	vlib $(MODE)work | tee $(COMPILE_LOG)
	vmap work $(MODE)work | tee -a $(COMPILE_LOG)

ifeq ($(MODE),standard) # Compiling in standard mode: no Veloce dependencies
	$(COMPILE_CMD) $(COMPILE_FLAGS) +define+$(KEY_WIDTH_MACRO) $(SRC_FILES) $(TST_FILES) | tee $(COMPILE_LOG)

else # Compiling either for Veloce, or Veloce puresim
	$(COMPILE_CMD) -f $(VMW_HOME)/tbx/questa/hdl/scemi_pipes_sv_files.f | tee -a $(COMPILE_LOG)
	$(COMPILE_CMD) $(COMPILE_FLAGS) +define+$(KEY_WIDTH_MACRO) $(SRC_FILES) $(TST_FILES) $(HVL_FILES) | tee -a $(COMPILE_LOG)

ifeq ($(MODE),veloce) # Compiling for puresim
	velanalyze $(COMPILE_FLAGS) +define+$(KEY_WIDTH_MACRO) $(SRC_FILES) $(TST_DIR)/Transactor.sv | tee -a $(COMPILE_LOG)
	velcomp -top Transactor | tee -a $(COMPILE_LOG)

endif # Compiling either for Veloce or Veloce puresim
	velhvl -sim $(MODE) | tee -a $(COMPILE_LOG)

endif

sim_subbytes:
	$(SIMULATE_CMD) SubBytesTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS) 

sim_shiftrows:
	$(SIMULATE_CMD) ShiftRowsTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS) 

sim_mixcolumns:
	$(SIMULATE_CMD) MixColumnsTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_addroundkey:
	$(SIMULATE_CMD) AddRoundKeyTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_round:
	$(SIMULATE_CMD) RoundTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_buffered_round:
	$(SIMULATE_CMD) BufferedRoundTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_expandkey:
	$(SIMULATE_CMD) ExpandKeyTestBench $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)

sim_encoder_decoder:
ifneq ($(MODE),standard)
	$(SIMULATE_CMD) EncoderDecoderTestBench Transactor $(SIMULATE_MANAGER) $(SIMULATE_FLAGS)
endif

all:
	$(MAKE) clean 
	
	for WIDTH in 128 192 256 ; do	\
		printf "\n$$KEY_MACRO\n" | tee -a $(SIM_LOG) ; \
		$(MAKE) compile KEY_WIDTH=$$WIDTH ; \
		$(MAKE) $(SIM_TARGETS) | tee -a $(SIM_LOG) ; done

	$(call check_sim)

clean:
	rm -rf work transcript $(SIM_LOG) $(COMPILE_LOG)
	rm -rf velocework puresimwork standardwork veloce.log veloce.med veloce.map tbxbindings.h 
	rm -rf velrunopts.ini modelsim.ini

