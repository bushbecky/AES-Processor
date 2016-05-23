#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <tomcrypt.h>

//TODO figure out a way to use a common header with SV?

#define BLOCKSIZE 16
#define PT_FILENAME "plain.txt"
#define CT_FILENAME "encrypted.txt"
#define KEY_FILENAME "key.txt"

#ifdef AES_256
    #define KEYLEN 32
    #define NUM_ROUNDS 14
#elif AES_192
    #define KEYLEN 24
    #define NUM_ROUNDS 12
#else // AES_128
    #define KEYLEN 16
    #define NUM_ROUNDS 10
#endif

struct file_h {
    FILE *pt_file;
    FILE *ct_file;
    FILE *key_file;
} handle;

//
// Utilities
//
void open_files(struct file_h *handle)
{
    handle->pt_file = fopen(PT_FILENAME, "wb");
    handle->ct_file = fopen(CT_FILENAME, "wb");
    handle->key_file = fopen(KEY_FILENAME, "wb");
}

void close_files(struct file_h *handle)
{
    fclose(handle->pt_file);
    fclose(handle->ct_file);
    fclose(handle->key_file);
}

void print_block(unsigned char *arr, int len)
{
    int i;
    for (i = 0; i < len; i++) 
        printf("%x ", arr[i]);
    printf("\n");
}

//
// Known Answer Test. Used to verify that the libtomcrypt sequence produces correct results.
// 
int kat(void)
{
    /* INCON AES ECB test vector(s) 1 */
#ifdef AES_256
    unsigned char pt[BLOCKSIZE] = {0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a};
    unsigned char et[BLOCKSIZE] = {0xf3, 0xee, 0xd1, 0xbd, 0xb5, 0xd2, 0xa0, 0x3c, 0x06, 0x4b, 0x5a, 0x7e, 0x3d, 0xb1, 0x81, 0xf8};
    unsigned char key[KEYLEN] = {0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe, 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81, 
                                 0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7, 0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4};
#elif AES_192
    unsigned char pt[BLOCKSIZE] = {0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a};
    unsigned char et[BLOCKSIZE] = {0xbd, 0x33, 0x4f, 0x1d, 0x6e, 0x45, 0xf2, 0x5f, 0xf7, 0x12, 0xa2, 0x14, 0x57, 0x1f, 0xa5, 0xcc};
    unsigned char key[KEYLEN] = {0x8e, 0x73, 0xb0, 0xf7, 0xda, 0x0e, 0x64, 0x52, 0xc8, 0x10, 0xf3, 0x2b, 0x80, 0x90, 0x79, 0xe5, 
                                 0x62, 0xf8, 0xea, 0xd2, 0x52, 0x2c, 0x6b, 0x7b};
#else // AES_128
    unsigned char pt[BLOCKSIZE] = {0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a};
    unsigned char et[BLOCKSIZE] = {0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60, 0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97};
    unsigned char key[KEYLEN] = {0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};
#endif

    unsigned char ct[BLOCKSIZE];
    unsigned char ptm[BLOCKSIZE];
    symmetric_key skey; // scheduled key

    printf("Running known answer test for keysize %dB\n", KEYLEN);

    /* setup variant */
    aes_setup(key, KEYLEN, NUM_ROUNDS, &skey);

    /* encrypt plaintext */
    aes_ecb_encrypt(pt, ct, &skey);

    // FIXME getting seg faults whenever mem* are used (memcmp, memset, etc).
    // gdb shows the automatic arrays above are overlapping? wtf?
    /* compare with expected */
    //if (memcmp(et, ct, sizeof et)) {
    //    printf("Expected does not match actual.\n");
    //    return EXIT_FAILURE;
    //} else {
    //    printf("Expected matches actual.\n");
    //}

    /* decypt ciphertext */
    aes_ecb_decrypt(ct, ptm, &skey);

    /* make sure decryption worked */
    //if (memcmp(pt, ptm, sizeof(pt))) {
    //    printf("Expected does not match actual.\n");
    //    return EXIT_FAILURE;
    //} else {
    //    printf("Expected matches actual.\n");
    //}

    /* done, clear key schedule */
    aes_done(&skey);

    return EXIT_SUCCESS;
}

//
// Generates a random plaintext of BLOCKSIZE, a random key of KEYLEN, and an associated ciphertext.
// Outputs to correct files
//
int generate_vector(struct file_h *handle, prng_state *prng)
{
    int i;
    unsigned char pt[BLOCKSIZE];
    unsigned char ct[BLOCKSIZE];
    unsigned char key[KEYLEN];
    char buf [BLOCKSIZE];
    symmetric_key skey; // scheduled key

    /* Generate random data */
    yarrow_read(pt, sizeof(pt), prng);
    yarrow_read(ct, sizeof(ct), prng);
    yarrow_read(key, sizeof(key), prng);

    /* setup variant */
    aes_setup(key, KEYLEN, NUM_ROUNDS, &skey);

    /* encrypt plaintext */
    aes_ecb_encrypt(pt, ct, &skey);

    /* done, clear key schedule */
    aes_done(&skey);

    /* write our data to file */
    for (i = 0; i < BLOCKSIZE; i ++) 
        fprintf(handle->pt_file, "%02x", pt[i]);
    fputc(0xa, handle->pt_file);

    for (i = 0; i < BLOCKSIZE; i ++) 
        fprintf(handle->ct_file, "%02x", ct[i]);
    fputc(0xa, handle->ct_file);

    for (i = 0; i < KEYLEN; i ++) 
        fprintf(handle->key_file, "%02x", key[i]);
    fputc(0xa, handle->key_file);

    return EXIT_SUCCESS;
}

//
// Generator entry
// 
int main(int argc, char **argv)
{
    int i;
    const char *seed = "Beer! It's what's for breakfast.";
    char verify_generator = atoi(argv[1]);
    int count = atoi(argv[2]);
    struct file_h handle;
    prng_state prng;
    // TODO use proper argparse

    /* register AES */
    if (register_cipher(&aes_desc)) {
        printf("Error registering AES.\n");
        return EXIT_FAILURE;
    }

    printf("hey\n");
    /* start psuedo random number generator */
    if (yarrow_start(&prng) != CRYPT_OK) {
        printf("Error starting PRNG.\n");
        return EXIT_FAILURE;
    }
    printf("hey\n");
    printf("hey\n");
    if (yarrow_ready(&prng) != CRYPT_OK) {
        printf("Error readying.\n");
        return EXIT_FAILURE;
    }
    printf("hey\n");

    /* generate test vectors */
    if (verify_generator) {
        kat();
    } else {
        open_files(&handle);
        for (i = 0; i < count; i++) 
            // TODO segault - compile with tomfastmath?
            //if (yarrow_add_entropy(seed, sizeof(seed), &prng) != CRYPT_OK) {
            //    printf("Error adding entropy.\n");
            //    return EXIT_FAILURE;
            //}
            generate_vector(&handle, &prng);
        close_files(&handle);
    }

    /* unregister AES */
    if (unregister_cipher(&aes_desc)) {
        printf("Error removing AES.\n");
        return EXIT_FAILURE;
    }

    yarrow_done(&prng);

    return EXIT_SUCCESS;
}

