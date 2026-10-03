# L1 MOS Programmer Guide — Chapter 8: Segments, Families and Processes

> Transcribed and OCR-cleaned from *olivetti - L1 MOS Programmer Guide, Sixth Edition,
> April 1987, Release 5.2* (publication code 4002570 L), PDF pages 207–230 (manual
> pages 8-1 to 8-24). Figures 8-7/8-8/8-9 are column-diagrams summarized in text
> rather than reproduced pixel-faithfully.

---

## 8. SEGMENTS, FAMILIES AND PROCESSES

*(page 8-1)*

This chapter describes how a program is executed in the L1 systems, illustrating the elements (segments, families, processes) on which program execution is based under the control of the MOS operating system.

The memory is seen as a set of **segments**, some of which are reserved for the system and some for the programs which, from the system's point of view, are users. Each segment is a continuous area of memory not greater than **64 Kbytes**.

The segments are the basic units which provide a logical address space.

The programs are sets of codes and data which are loaded in memory, starting with the files (which have a loadable format and are known as **l-modules**) created by the linker.

When a series of program statements are executed this is known as a **process**. The processes are potentially independent of each other, and are the primary agents of the processing procedures.

One of the system components (the **PMM**, Process and Memory Management) [serves] to prepare the program execution environment. This means handling the logical address space where the program resides, loading the program in the physical memory, activating the program's execution by creating the relative process and assigning it control of the CPU.

## FAMILIES

*(page 8-2)*

The processes are grouped into two categories:

- Coresident
- Disjointed

A **family** is formed by one or more processes. The family is assigned control of the processing, which means that it has visibility of the logical segments. The **coresident** processes share the family's address space (except for the stack — each process has its own). They cooperate in executing the family's activities: they can pass control among themselves (when the running process suspends) without causing the rescheduling of the activities to be executed.

Control of the processor among the various active families (those which have at least one ready process) is assigned for a **time slice**.

A series of information (size, physical location and attributes of the segments used) is stored for each process in appropriate registers handled by the **MMU (Memory Management Unit)**.

> **Note:** Each L1 MOS system is equipped with one MMU, except the **M60** which may be equipped with either one or two MMUs. The following description applies to systems with one MMU. See the section "M60 With Two MMUs" for further information about this specific case.

When control of the processor is taken from a process and passed to another belonging to the same family, the contents of the two registers are saved in a table (handled by the PMM) so that that process can correctly restart its execution at a later date (**Partial Context Switch**).

**Disjointed** processes belong to different families whose activities are not strictly connected. Control of the central unit is assigned to these processes according to the priority of their family.

When, however, the new process must take control from another family, the contents of all the MMU registers are saved with information on the user segments used by the family to which the process which has lost control belonged (**Context Switch**).

The table in which this information is saved (**PMM Segment Table**) thus contains information relating to the 30 user segments used by each family, plus that relating to the 2 segments characterizing each process.

**Fig. 8-1 — PMM Segment Table (1 MMU only)**
A table indexed by family (family 0 = system family, family 1, family 2 … family n), each family holding its process entries (process 1, process 2 … process m).

The information contained in this table allows the PMM to handle parallel execution of separate families (**multiprogramming**). See the section "Assigning CPU Control to the Families" later in this chapter for further details.

## SEGMENT ALLOCATION TO THE FAMILIES

*(page 8-3 → 8-4)*

The families are created according to a hierarchic structure. A "father" family exists for all the others which creates "son" families. Each of these can create others, which will be their "sons", and so on.

When a family has control of the central unit (when it is active) it uses a total of **64 logical segments** for its address space.

**Fig. 8-2 — The Segments (1 MMU only)**

| Segments | Use |
|---|---|
| 0 – 31 | system segments |
| 32 – 61 | user segments |
| 62 – 63 | system segments (associated to each process) |

The segments from **0 to 31** inclusive are allocated to the operating system, and contain the system's code and data area. These segments are shared among all the families, including those which are created during a processing.

Segments **32 to 61** are known as **user segments**, and are allocated to a family. They are shared between all the coresident processes of this family and contain the data and code of the user programs (for example, the Shell command interpreter, the BASIC interpreter, an application program, etc). One of these programs can occupy more than one segment. The allocation of particular user segments to the code and data area of the application programs can be requested by the user during the linking phase, via a suitable linker option (**OLINK** or **ZLOC**).

Segments **62 and 63** belong to each process (each coresident process of the family has a copy of these two segments). Segment 62 is reserved for the system, whilst segment 63 is the process's stack.

## M60 WITH TWO MMUs

*(page 8-5)*

The M60 system may be equipped with a second MMU. In this case the number of segments is doubled: the total number of logical segments is **128**. They are grouped as shown in the following figure.

**Fig. 8-3 — The Segments (M60 with two MMUs)**

| Segments | Use |
|---|---|
| 0 – 31 | system segments |
| 32 – 61 | user segments |
| 62 – 63 | system segments (associated to each process) |
| 64 – 127 | system segments (added by second MMU) |

The second MMU adds a set of logical segments (**64–127**) which are used by the system and which expand the configurability features.

## FAMILY ATTRIBUTES

*(page 8-6)*

When a new family is to be created, the father family can assign a series of attributes to the son which determine its execution environment:

- **priority:** is the priority of all the processes of the new family.
- **time slice:** is the time slice assigned to the new family.
- **budget:** is the number of memory pages (each with **256 bytes**) to be allocated to the new family.
- **private segments:** is the number of segments which will be considered private property of the new family (apart from segments 62 and 63, which are always private property of a process).

The new family's address space is initially empty, except for the system segments (0–31) which all the families have. The segment area which has been defined as private property of the new family is that included between the highest available user segment (61) and the highest private segment of the father family.

The segments which are lower than this last are shared among the father and its son, therefore the son is not given exclusive control of them.

A series of detailed information can be obtained on the segments, families and processes using the **NOSE** utility program, which can be activated in the Shell environment.

## ASSIGNING CPU CONTROL TO THE FAMILIES

*(page 8-6 → 8-7)*

The **time-sharing** policy is used for sharing the CPU between the families.

A family is defined as a set of processes which reside in the same address space. A family is active when at least one of its processes is carrying out an activity of the family.

CPU control is assigned to a family by the system: the family's processes have equal priority and can use the CPU without being interrupted by another process of the same family. When a process suspends to wait for a resource or an event, CPU control is assigned to another process of the same family.

The decision not to interrupt a process in favour of another of the same family is made because the two processes cooperate in executing the family's activities and so there is no reason to consider them as competing for CPU control.

The time-sharing policy is used for handling the families. When a new family is created, it is given a time-slice value. This value is a multiple of the system's time unit, which is equal to **100 msec**.

This value indicates the time for which a family can control the CPU, unless other families with a higher priority become available in the meantime (see the section below "FAMILY PRIORITY") with at least one "ready" process.

When a family's time-slice expires, CPU control is taken from the process currently using it and given to another family.

If the time-slice value has been defined as **less than zero**, the family cannot be interrupted. In other words, when the CPU is assigned to a ready process of this family, the process only releases it when it has finished its activity or when it suspends to wait for a resource or an event.

This possibility allows families executing activities in **real time**, where the time-slice policy cannot be applied, to be handled simultaneously with families whose activities allow this policy to be used. The latter type of activity is executed when there are no real time activities in progress.

### FAMILY PRIORITY

When a family is created, it is assigned a priority. This priority is used to identify all the processes belonging to that family.

A new family is created by an existing family and the latter is then known as the father: in order to guarantee that the father family always has control of its sons, the new family's priority is the value assigned to it plus that of the father family.

The highest priority value is **1**, and the lowest is **32767**.

The family with the highest priority is the one which executes **Grandpa's** activities. It receives CPU control as soon as the IPL phase has finished and it creates the families which will execute the activities forecast in Grandpa's configuration file (assigning them the priority decided by the user): this family is, therefore, known as the father of all the families. When a family dies, because its activities have finished, control is returned to its father family (the family which requested its creation).

The user can determine the families' execution priority during the normal system activities. The **PRIOR** command is available for this purpose, and can be activated in the Shell environment. It lowers the priority of all the programs activated after it has been called.

The value supplied by the user is added to the values of the family priorities that are to be created. In this way they are penalized, from the point of view of execution priority, compared with the activities that were already in progress when the command was carried out.

*(page 8-7)* To return to the previous situation, in order to eliminate any alterations to the priorities assigned by the user, this last can simply call the PRIOR command with a value of **0** as its parameter.

## SEGMENT TYPES AND ATTRIBUTES

*(page 8-8)*

Each segment is characterized by a **type** and a series of **attributes** which can be assigned during the linking phase, via the **ATTRIBUTES** command of the linkers (OLINK or ZLOC).

The segment "type" informs the system of its contents and how to handle it. The table below lists the possible types.

**Tab. 8-4 — Segment Types**

| Type | Name | Segment contents description |
|---|---|---|
| 1 | XQTCODE | execute-only code |
| 2 | RDCODE | code which can be executed and/or read |
| 3 | RWCODE | code which can be read and/or written |
| 4 | RDDATA | read-only data |
| 5 | RWDATA | data which can be read and/or written |
| 6 | STACK | process stack |
| 7 (*) | RLRDCODE | relocatable read-only code |
| 8 (*) | RLRWCODE | relocatable code which can be read and/or written |
| 9 (*) | RLRDDATA | relocatable read-only data |
| 10 (*) | RLRWDATA | relocatable data which can be read and/or written |

(*) The relocatable segments are reserved for the interpreted programs.

Types **1, 2, 4, 7 and 9** identify the segments which can be shared among several families. That is, if the same l-module is loaded by more than one family, segments of type 1, 2, 4, 7 and 9 are loaded only once.

*(page 8-9)* A segment's "attribute" determines the type of **hardware protection** to be set. The following table lists the possible attributes.

**Tab. 8-5 — Segment Attributes**

| Attribute | Description |
|---|---|
| RDWRT | the segment can be accessed for execution or for read and/or write operations |
| RDONLY | the segment can be accessed for execution or for read operations |
| XQTONLY | the segment can be accessed for execution only |
| STCKATTR | the segment is used as stack |

The segments which should have different "type" or "attribute" values from those indicated in the previous two tables, or which might present incongruencies between these two values, could not be loaded into memory. It is the responsibility of the user, whenever he does not use the linker automatically, to guarantee their correctness and compatibility.

### Modifying the Size of the Segments

The system analyst can alter the size of one or more user segments. This is done by giving a signed value, when the **Setsegment** primitive is called (see the manual "PMM and Driver Primitives - Reference Manual"), which expresses the unit number (each of **256 bytes**) by which the size of the segment must be increased or reduced (according to whether the value is positive or negative).

Only the size of segments **3, 5, 6, 8 and 10** can be modified. The size of the segments reserved for the system cannot be modified.

## ASSIGNING AND USING THE USER SEGMENTS

*(page 8-9 → 8-10)*

When the system has been initialized, control is passed to the process which must start all the forecast activities. This process, known as **Grandpa**, is the "father" of all the families. A detailed description of its functions is given in the Chapter "Activating the Programs and User Subsystem" later in this manual.

When Grandpa has loaded all the user packages indicated in its configuration file (for example, the QUEMAN queue manager, the Message Switching functions package of a Transaction Handler, if forecast, etc), it establishes which is the segment with the highest number currently being used in its address space, apart from the segments used by Grandpa itself.

The segments with lower numbers will be shared among all the families. Therefore, all the private segments allocated to the families created by Grandpa, and their eventual descendents, will have higher numbers than this.

It is possible that some of the user segments included among those established by Grandpa as shared among the families are, in fact, not used. This is the ideal segment for loading an eventual functions package written by the user (and to be indicated during the linking phase of that package).

The user identifies which eventual free segments will be used for this purpose, bearing in mind that the system packages loaded by Grandpa are located as indicated in the table below. Information is not given on segments reserved for components resident in private spaces and which therefore do not influence the program preparation activities.

**Tab. 8-6 — User Segment Allocation** *(pages 8-11, 8-12)*

| Component | Allocated segments |
|---|---|
| **COMMIT** | 40, 41 |
| **Login Program** | 55, 56, 57 |
| *User Packages:* | |
| QUE LMS (QUEMAN & LMS) | 32 |
| QUEMAN | 32 |
| NMS | 34, 35, 39 |
| MSWMAN (Message Switching) | 33 |
| MTSCTLG (MTS) | 34 |
| MTSCTLG & CSCHEMA (MTS) | 34 |
| BEAMMON (BEAM) | 34, 35 |
| SLAM (ONE) | 36 |
| EEAUP (NEMOS) | 36 |
| WBF (Term. Emul.) | 37, 38 |
| LUINTERFACE1 (Term. Emul.) | 37, 38 |
| LUINTERFACE2 (Term. Emul.) | 37, 38 |
| *MTS:* | |
| SMAN | 39, 40, 41 |
| LMAN | 39, 41 |
| GMAN | 39, 45 |
| TUMAN | 42, 45, 46 |
| GTSMAN | 42, 45, 46 |
| COMAN | 40, 41 |
| TBMAN | 40, 41 |
| ESCHEMA | 43, 44 |
| OVLSMAN | 43, 44 |
| OVLGMAN | 46, 47 |
| BUFSEC | 42 |
| BUFTU | 43 |
| BUFITSC | 44 |
| *Graphics:* | |
| PGU | 43, 44, 45 |
| RTGSP | 43, 44, 45, 46, 47 |
| *VISA:* | |
| MONITOR | 42 |
| INTERPRETER | 55, 57, 59, 61 |
| *COBOL:* | |
| RTS | 56, 57, 58, 59, 60, 61 (*) |
| *BASIC:* | |
| RTS | 57, 58, 59, 60, 61 |
| *FORTRAN:* | |
| Default allocation for user programs | 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 60, 61 |
| *PASCAL+:* | |
| Default allocation for user programs | 59, 60, 61 |

(*) Segment 56 is only occupied if the SORT utility is used. Segment 60 may be not occupied if a reduced configuration of the Run Time is present.

*(page 8-13)* In order to avoid the danger of a family attempting to create a son family and allocating it a segment which is already occupied, when the user-written programs are linked the user must ensure that the segments are allocated in **descending order**, starting from the highest allowed (61), using the **BLOCK DESCRIPTOR** command of the linkers (OLINK or ZLOC).

### Supplementary Notes on the Use of the User Segments

From now on, the first free segment whose number is immediately above those occupied by all the user packages will be referred to as **"GPASEG"**. GPASEG has a variable value depending on which packages have been loaded by Grandpa (from the system packages listed in the table above, or other user-written packages — see the section "The User Packages").

The created families can use the segments between **GPASEG and 61** (this is the segment with the highest number available to the user).

In order to pass CPU control between the families, each one must have customized segments available, according to the segment visibility given to them by the 'father'. This means that a segment's contents may vary according to the family in execution.

This concept allows alternated execution of unconnected families which are dedicated to different activities, and each family is guaranteed a large number of available segments.

Segment availability for certain application environments or programs, activated by Grandpa, is summarized below. The diagrams should provide a simple graphic explanation of how the user segments are assigned and used. Each vertical column represents a family. The name of the activity carried out by this family is given at the top of the column, with indications in the column on the contents of the segments and the family's visibility of them.

- Family creation is indicated by an arrow (→).
- The value given in brackets in the arrow indicates the number of **private** segments assigned by the creator family to the new family.
- The value indicated by **(X)** is the result of the expression (30 − the number of segments reserved for the user packages).
- If the value is given as **(S)**, it means that the creator family assigns the same number of private segments as it has to the family which it creates.
- The components which are indicated in brackets are optional: they may not be present.

*(page 8-13 → 8-14)* Programs activated with the **INIT** and **TERM** commands have a family available whose address space goes from **32 to 61**. These programs exist only when system activities are initialised and terminated and they are therefore not considered as contending for segment use.

The user packages loaded with the **CALL** or **PCALL** command are allocated in the Grandpa family. The loading of the user packages determines the range of the segments that Grandpa assigns to the interactive and non-interactive programs. The interactive programs are allocated in the address which goes from **GPASEG to 61**.

Programs activated with commands **TTYx, ALLT** and all non-interactive programs activated with commands **FG, START, BG and PFG** have a family available whose address space goes from **GPASEG to 61**.

**Shell** — The Shell program is activated in a family which goes from GPASEG to 61. The application program activated by Shell is resident on a family, daughter of the Shell family, which goes from GPASEG to 61.

**Graphics** — The PGU graphics package is loaded into the same address space as the program which uses it and is allocated to the segments in the range from **43 to 45**. RTGSP, on the other hand, is allocated to the segments in the range from **43 to 47**.

**MTS** — The MTS software environment requires the CSCHEMA and MTSCTLG packages loaded by CALL in the Grandpa configuration file in segment 34. To permit the activation of transactional and/or interactive environments **GPASEG must be ≤ 39**. The family executing the controller program of the interactive activities (consisting of either SMAN or LMAN) can use the segments from GPASEG to 61.

The interactive program is executed in the same family as the controller program and, therefore, can use the segments from GPASEG to 61 with the exception of those occupied by SMAN (or LMAN), ESCHEMA, COBOL Run Time Support, graphics and VISA.

The **OVLSMAN** module, which is the transient part of the CE (Client Environment), is loaded by SMAN into the segments 43 and 44 and unloaded before the ESCHEMA uses them.

*(page 8-15)* The application program cannot occupy the segments occupied by OVLSMAN because this module executes the application program loading before ESCHEMA unloads it.

In case of program structured in overlays, only the MAIN module related to them cannot be loaded in the segments occupied by OVLSMAN which, however, can be occupied by overlays loaded subsequently.

In case of PASCAL+ programs, the program loaded by OVLSMAN cannot occupy the segments occupied by this module, but these segments can be occupied by other programs activated by the first one.

The 'main' program of the transactional environment (consisting of MAIN) can use the segments from GPASEG to 61. It is activated by START or FG in the Grandpa configuration file. This 'main' creates the families which execute the Servers; these families can use the segments from **47 to 61**, with the exception of those occupied by COBOL Run-Time Support (for Server Programs written in COBOL).

The **OVLGMAN** module, which is the transient part of the SE (Server Environment), is loaded (and unloaded) by GMAN into the segments 46 and 47.

It must be remembered that an **incompatibility exists between graphics and the Chained Data Base**.

**Fig. 8-7 — MTS System** *(page 8-16)*
A per-segment (32–61) column map of the MTS environment showing where each module lands: seg 32 = QUEMAN/QUE LMS; 33 = MSWMAN; 34 = MTSCTLG / MTSCTLG & CSCHEMA; 36 = SLAM/EEAUP; 37–38 = Terminal Emulators; the MTS-CE branch created with (X) private segments and the MTS-SE branch; 39–41 = SMAN/LMAN, GMAN, COMAN/TBMAN; MTS-Serv created with (20); 42 = VISA Mon. / BUFSEC / TUMAN/GTSMAN; 43–44 = ESCHEMA / OVLSMAN / BUFITSC; the GMAN, OVLGMAN and TUMAN/GTSMAN server columns; 55–61 = RTS (Sort) / VISA / GPA. Where `****` appears it can be any combination of **STDSR** (Standard Server), **ITSC** (Inter Transactional System Communication) or **DUALLOG** (secondary log update handler).

*(page 8-17)* **COBOL Program** — When a COBOL program is activated, the language's Run-Time Support is loaded into the segments from **56 to 61** of the family executing the program.

The program may therefore be loaded in the segments from GPASEG to 55, and also in segments 56 and 60 if the SORT utility is not used, and if a configuration with reduced Run Time is present.

- If graphics are used, GPASEG must be ≤ 43 and the program cannot use the segments reserved for the graphics.
- If VISA is used, GPASEG must be ≤ 42 and the program cannot occupy the segment occupied by the VISA Monitor.
- If the program is executed under COMMIT, GPASEG must be ≤ 40 and the program cannot occupy the segments occupied by COMMIT.
- If the Debugger is used, GPASEG must be ≤ 41.

**Fig. 8-8 — System with a COBOL Program which Uses VISA and Graphics Under COMMIT** *(page 8-18)*
Column map: Shell created with (X) → Appl. Progr. created with (S); COMMIT (segs 40–41), VISA Mon. (42), VISA Int. created with (X).

*(page 8-19)* **Compiled BASIC Programs** — When a Compiled BASIC program is activated, the language's Run-Time Support is loaded into the segments from **57 to 61** in the address space of the family executing the program. The program must, therefore, be loaded into the segments from GPASEG to 56.

- If graphics are used, GPASEG must be ≤ 43 and the program cannot occupy the segments occupied by the graphics.
- If the program is executed under COMMIT, GPASEG must be ≤ 40 and the program cannot occupy the segments occupied by COMMIT.
- If the Debugger is used, GPASEG must be ≤ 41.

**Fig. 8-9 — Debug of a BASIC Program which Uses VISA and Graphics Under COMMIT** *(page 8-20)*
Column map: Shell created with (X) → (S); COMMIT (40–41), Debuginit (X), Appl. Progr. (X), VISA Mon., VISA Int. (X), RTGSP/PGU; SYMDEB and RTBAS columns.

*(page 8-21)* **PASCAL+ Programs** — The program can be loaded in the segments from GPASEG to 61. Default allocation is in the segments from **59 to 61**.

- If graphics are used, GPASEG must be ≤ 43 and the program cannot occupy the segments occupied by the graphics.
- If VISA is used, GPASEG must be ≤ 42 and the program cannot occupy the segment occupied by the VISA Monitor.
- If the program is activated under COMMIT, GPASEG must be ≤ 40 and the program cannot occupy the segments occupied by COMMIT.
- If the Shell commands are activated, GPASEG must be ≤ 43.
- If the PASCAL+ Debugger is used, GPASEG must be ≤ 42.

**FORTRAN Programs** — The program can be loaded in the segments from GPASEG to 61. Default allocation is in the segments from **48 to 58** and in the segments 60 and 61.

- If graphics are used, GPASEG must be ≤ 43 and the program cannot occupy the segments occupied by the graphics.

**Batch** — The batch function is performed by the **BTCHGPA** module activated by Grandpa with a START, and by the QUEMAN module loaded in segment 32 with a PCALL by Grandpa. BTCHGPA then generates a family in which the UNSPOOL program executing the batch activities is activated.

**Spool** — The spool function is performed by the **SPGPA** module loaded by Grandpa with a START, and by the QUEMAN module loaded in segment 32 with a PCALL by Grandpa. SPGPA then generates a family in which the UNSPOOL program executing the spooling activities is activated.

**BEAM** — The BEAM is composed of two modules: **BEAMMON** and **BEAM**. The BEAMMON is loaded by Grandpa with a CALL in the segments 34 and 35. The BEAM is loaded in the segments 54 and 55 of a family created by Grandpa whose address area goes from GPASEG to 61.

Programs that can be activated by BEAM are loaded in the address space that goes from GPASEG to 61 of a family created by the BEAM module. *(page 8-22)* If the activity requires an interpreter the BEAM module creates a family whose address space goes from GPASEG to 61, in which the interpreter is loaded.

**Symbolic Debugger** — When the Debugger is activated, the MAIN module is loaded in the address space of the family which executes the program which invoked the Debugger. This module creates two families and loads in their address space the program to be debugged and the BT module which initialises the Debugger.

**VISA** — The VISA component consists of a monitor and an interpreter. Segment **42** of the family executing the application program which has called the VISA function is allocated to the monitor. The interpreter is loaded into segments **55, 57, 59 and 61** of a new family, created by the application program which is executing the requested VISA functions. As both the interpreter and the application program have to access the monitor, segment 42 must be shared between their families and it cannot be used by the application program.

**Message Switching** — The Message Switching service is executed by the module **MSWMAN**, which is loaded by means of a CALL in the Grandpa configuration file at segment 33, and by the modules **MSWDIS, MSWROUTER or MSWLOCAL**, activated by Grandpa in a START operation.

**LMS** — The LMS service is executed by the module **SYSLOG**, which is activated by Grandpa with a START operation, and by the module **QUE_LMS**, loaded with a call from Grandpa at segment 32.

**NMS** — The NMS user packages are loaded by a CALL from Grandpa in segments **34, 35 and 39**. These are only used by the CMS component (Central Monitoring System) and are only installed on the machine that controls the network.

**SLAM** — The ONE user package (SLAM) is activated by a call from Grandpa, in segment **36**.

*(page 8-23)* **NEMOS** — The Network Monitoring service of the SNA network is controlled by the user package **EEAUP** activated by a CALL from Grandpa, in segment **36**.

### Conclusions

An understanding of the organization of segment occupation means that the correct segment in which to load a user-written function package may be identified (see the Section "Notes on Writing a User Package").

Some general conclusions can be made on the basis of the information given so far, bearing in mind that segment occupation in a system must be evaluated by the user according to the components which are used.

For **stand-alone or application/terminal server systems**, an incompatibility currently exists between:
- Terminal Emulators
- BEAM and MTS
- ONE network and NEMOS (network monitoring SNA).

This means that these application environments are mutually exclusive and cannot coexist simultaneously in a system: they can, however, both be used separately, each time initializing the system with different Grandpa configuration files. Each file requests the desired environment to be loaded.

The MTS application environment can coexist on a system with graphic functions if these are not called by the interactive program of the transaction application. (They are, instead, available to other programs which are not part of this application.) The Server Environment of the transaction application may use neither graphics nor I/O towards the screen.

For **LAN multiserver systems**, an incompatibility currently exists between:
- BEAM and MTS application environments if the respective servers reside on the same system
- BEAM and NMS (mutually exclusive if resident on the same system)
- NMS and MTS (mutually exclusive if resident on the same system)
- ONE network and NEMOS (mutually exclusive if resident on the same system)

Furthermore, the terminal emulators must reside on the same system (identified by the logical name 128) as the Line Manager.

## USER VISIBILITY OF THE MEMORY OCCUPATION

*(page 8-24)*

The user can find out the memory occupation value of a program via the **CSIZE** command, which can be activated in Shell environment. It provides information relating to:

- the memory occupation of one or more **l-modules** (files in loadable format created by the linker) indicated by the user calling the command
- the segments allocated to these l-modules.

The occupation value given by this command refers to the memory occupation of the specified program, and not the space on disk occupied by the file containing the program.

A program's memory occupation can be found out without that program being loaded in memory: in other words the CSIZE command can be executed for a program which is not currently in memory but is resident on disk.
