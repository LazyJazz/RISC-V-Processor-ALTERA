#include <iostream>
#include <cstring>
#include <cstdio>
#include <elf.h>
using namespace std;

union FPGAMem
{
    uint32_t word[4096];
    uint8_t byte[16384];
}fpga_mem;

void PrintFPGAMem(FPGAMem *fpga_mem, const char * file_path)
{
    FILE * file = fopen(file_path, "wb");
    for (int addr = 0; addr < 16384; addr+=4)
    {
        uint8_t vercode = 0;
        vercode -= 4;
        vercode -= ((addr >> 2) & 255);
        vercode -= ((addr >> 10) & 255);
        vercode -= fpga_mem->byte[addr];
        vercode -= fpga_mem->byte[addr + 1];
        vercode -= fpga_mem->byte[addr + 2];
        vercode -= fpga_mem->byte[addr + 3];
        fprintf(file, ":04%04X00%02X%02X%02X%02X%02X\n", addr >> 2, fpga_mem->byte[addr + 3], fpga_mem->byte[addr+2], fpga_mem->byte[addr+1], fpga_mem->byte[addr], vercode);
    }
    fprintf(file, ":00000001FF\n");
    fclose(file);
}

void PrintFPGAMemBin(FPGAMem *fpga_mem, const char * file_path)
{
    FILE * file = fopen(file_path, "wb");
    for (int i = 0; i < 4096; i++)
    {
        char bit[32];
        int word = fpga_mem->word[i];
        for (int i = 0; i < 32; i++)
        {
            bit[i] = (word & 1) + '0';
            word >>= 1;
        }
        for (int i = 31; i >= 25; i--)
            fputc(bit[i], file);
        fputc(' ', file);
        for (int i = 24; i >= 20; i--)
            fputc(bit[i], file);
        fputc(' ', file);
        for (int i = 19; i >= 15; i--)
            fputc(bit[i], file);
        fputc(' ', file);
        for (int i = 14; i >= 12; i--)
            fputc(bit[i], file);
        fputc(' ', file);
        for (int i = 11; i >= 7; i--)
            fputc(bit[i], file);
        fputc(' ', file);
        for (int i = 6; i >= 0; i--)
            fputc(bit[i], file);
        fputc('\n', file);
    }
    //fprintf(file, ":00000001FF\n");
    fclose(file);
}

int main()
{
    Elf32_Ehdr hdr;
    FILE * file = fopen("main", "rb");
    fread(&hdr, sizeof(hdr), 1, file);
    printf("Number of Section Headers: %d\n", (int)hdr.e_shnum);
    printf("Offset of Section Headers: %d\n", (int)hdr.e_shoff);
    printf("Size of Section Headers: %d\n", (int)hdr.e_shentsize);
    printf("Program Entry: %08x\n",hdr.e_entry);
    int n_shdr = hdr.e_shnum;
    printf("       \t     \tName   \tAddress \tSize    \tOffset  \tFlag\n");
    int shstrtaboff = 0;
    
    Elf32_Shdr shdr;
    fseek(file, (int)hdr.e_shoff + hdr.e_shstrndx * (int)hdr.e_shentsize, SEEK_SET);
    fread(&shdr, sizeof(shdr), 1, file);
    shstrtaboff = shdr.sh_offset;
    for (int i = 0; i < n_shdr; i++)
    {
        int offset = (int)hdr.e_shoff + i * (int)hdr.e_shentsize;
        Elf32_Shdr shdr;
        fseek(file, offset, SEEK_SET);
        fread(&shdr, sizeof(shdr), 1, file);

        char sec_name[1024] = {};
        fseek(file, shstrtaboff + shdr.sh_name, SEEK_SET);
        fscanf(file, "%s", sec_name);
        sec_name[7] = 0;
        printf("Section\t[%d]:\t%s\t%08x\t%08x\t%08x\t%08x\n", i, sec_name, (int)shdr.sh_addr, (int)shdr.sh_size, (int)shdr.sh_offset, (int)shdr.sh_flags);
        if ((shdr.sh_flags & 2) == 2 && shdr.sh_type == 1)
        {
            fseek(file, shdr.sh_offset, SEEK_SET);
            fread(fpga_mem.byte + shdr.sh_addr,1, shdr.sh_size, file);
            puts("Copied.");
            // if (std::string(sec_name) == ".data")
            //     printf(".data: %s\n", fpga_mem.byte + shdr.sh_addr);
            // if (std::string(sec_name) == ".rodata")
            //     printf(".rodata: %s\n", fpga_mem.byte + shdr.sh_addr);
        }
    }
    fclose(file);
    fpga_mem.word[4094] = 0b111110110111 | ((hdr.e_entry + ((hdr.e_entry & 0x800)?0x1000:0)) & 0xfffff000);
    fpga_mem.word[4095] = 0b11111000000001100111 | ((hdr.e_entry & 0xfff) << 20);
    PrintFPGAMem(&fpga_mem, "memory_init.hex");
    PrintFPGAMemBin(&fpga_mem, "main.cbin");
}