### nctuOS

A tiny OS that used for course OSDI in National Chiao Tung University, Computer Science Dept.

This OS only supports x86

### Lab 4

In this lab, you will learn about memory management in x86.

You can leverage `grep` to find out where to fill up to finish this lab.

`$ grep -R TODO .`

To run this kernel

    $ make
    $ qemu -hda kernel.img -monitor stdio

- Modify `kernel/mem.c` to implement the memory management functions
- Modify `kernel/trap.c` and `kernel/trap_entry.S` to setup IDT for pagefault


### Acknowledgement

This is forked and modified from MIT's Xv6

## 4.1 Physical Memory Management
- kernel/mem.c
    - using ```boot_alloc``` allocate pages
    ```c
    pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo) * npages);
	memset(pages, 0, sizeof(struct PageInfo) * npages);
    ```
    - page_init()
    ```c
    for (i = 0; i < npages; i++) {
	
		if(i == 0){
			pages[i].pp_ref = 1;
        		pages[i].pp_link = NULL;

		}	
		else if(i < npages_basemem){
 			pages[i].pp_ref = 0;
        		pages[i].pp_link = page_free_list;
        		page_free_list = &pages[i];
		}
		else if(i < (EXTPHYSMEM / PGSIZE) || i < ((uint32_t)nextfree - KERNBASE) / PGSIZE){
			pages[i].pp_ref = 1;
        		pages[i].pp_link = NULL;
		}
		else{
			pages[i].pp_ref = 0;
        	pages[i].pp_link = page_free_list;
        	page_free_list = &pages[i];
		}

    }
    ```
    - page_alloc()
    ```c
    struct PageInfo* page_alloc(int alloc_flags)
    {
        /* TODO */
        if (page_free_list == NULL) return NULL;
        struct PageInfo *pp = page_free_list;
        page_free_list = page_free_list->pp_link;
        if (alloc_flags & ALLOC_ZERO)
            memset(page2kva(pp), 0, PGSIZE);
        pp->pp_link = NULL;
        return pp;
    }
    ```
    - page_free()
    ```c
    void page_free(struct PageInfo *pp)
    {
        // Fill this function in
        // Hint: You may want to panic if pp->pp_ref is nonzero or
        // pp->pp_link is not NULL.
        /* TODO */
        assert(pp->pp_ref == 0);
        assert(pp->pp_link == 0);
        pp->pp_link = page_free_list;
        page_free_list = pp;
    }
    ```
## 4.2 Page Table Management (Virtual Memmory)
- kernel/mem.c
    - pgdir_walk()
    ```c
    pte_t * pgdir_walk(pde_t *pgdir, const void *va, int create)
    {
        // Fill this function in
        /* TODO */
        pde_t *pde = &pgdir[PDX(va)];
        pte_t *pte_kva;
        if(*pte & PTE_P)
            pte_kva = KADDR(PTE_ADDR(*pte));
        else{
            struct PageInfo *pp;
            if(!create || !(pp = page_alloc(ALLOC_ZERO))) return NULL;
            pp->pp_ref++;
            pte_kva = page2kva(pp);
            *pde =  page2pa(pp) | PTE_P | PTE_U | PTE_W;
        }
        return &pte_kva[PTX(va)];
    }
    ```
    - boot_map_region()
    ```c
    static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
    {
        /* TODO */
        while(size >= PGSIZE){
            pte_t *pte = pgdir_walk(pgdir, va, 1);
            *pte = pa | perm | PTE_P;
            pa += PGSIZE;
            va += PGSIZE;
            size -= PGSIZE;
        }
    }
    ```
    - page_lookup()
    ```c
    struct PageInfo* page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
    {
        /* TODO */
        pte_t *pte = pgdir_walk(pgdir, va, 0);
        if(!pte || !(*pte & PTE_P)) return NULL;
        if(pte_store) *pte_store = pte;
        return pa2page(PTE_ADDR(*pte));
    }
    ```
    - page_insert()
    ```c
    int page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
    {
        /* TODO */
        pte_t *pte = pgdir_walk(pgdir, va, 1);
        if (!pte) return -E_NO_MEM;
        if (*pte & PTE_P){
            if (PTE_ADDR(*pte) == page2pa(pp))
                goto PAGE_INSERT_SUCCESS;
            page_remove(pgdir, va);
        }
        pp->pp_ref++;
        tlb_invalidate(pgdir, va);
    PAGE_INSERT_SUCCESS:
        *pte = page2pa(pp) | perm | PTE_P;
        return 0;
    }
    ```
    - page_remove()
    ```c
    void page_remove(pde_t *pgdir, void *va)
    {
        /* TODO */
        pte_t *pte;
        struct PageInfo *pp = page_lookup(pgdir, va, &pte);
        if (!pp) return;
        page_decref(pp);
        *pte = NULL;
        tlb_invalidate(pgdir, va);	
    }
    ```
## 4.3 Static Mapping
- kernel/mem.c
    - mem_init
    ```c
    boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
    boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
    ```
## 4.4 Page Fault Handler
- kernel/trap_entry.S
    -  TRAPHANDLER_NOEC(trap_page_fault, T_PGFLT)
- kernel/trap.c
    - trap_init()
    ```c
    /* page fault */
	extern void trap_page_fault();
	SETGATE(idt[T_PGFLT], 0, GD_KT, trap_page_fault, 0);
    ```
    - trap_dispatch()
    - Add ```trap_page_fault_handler()```
