CHUNKSERVERS=1 \
	DISK_PER_CHUNKSERVER=1 \
	USE_RAMDISK=YES \
	MOUNT_EXTRA_CONFIG="mfscachemode=NEVER" \
	MASTER_EXTRA_CONFIG="CHUNKS_LOOP_TIME = 1|OPERATIONS_DELAY_INIT = 0" \
	setup_local_empty_lizardfs info

cd "${info[mount0]}"

# Create a file
FILE_SIZE=123456 file-generate file

# Restarft the chunkserver and overwrite the file
mfschunkserver -c "${info[chunkserver0_config]}" restart
lizardfs_wait_for_all_ready_chunkservers
FILE_SIZE=234567 file-generate "$TEMP_DIR/newfile"
dd if="$TEMP_DIR/newfile" of=file conv=notrunc

# Check if there are chunks with version different than 1
number_of_chunks=$(find_chunkserver_chunks 0 | grep -v '_00000001[.]' | wc -l)
if (( number_of_chunks != 1 )); then
	test_fail "Chunk didn't change version after modifying"
fi

# Check if we can read the modified chunk
file-validate file
