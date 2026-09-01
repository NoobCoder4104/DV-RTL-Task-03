# FIFO Knowledge Base Entry

## Topic: Synchronous FIFO Design

### What is a FIFO?

**FIFO** stands for **First-In-First-Out**. It's a queue data structure where:
- Data written first exits first
- Like a line at a store: first person in line is first to be served

### Where FIFOs Are Used

1. **Clock Domain Crossing** — buffering between different clock domains
2. **Rate Matching** — producer and consumer have different speeds
3. **Burst Buffering** — temporary storage for bursty data
4. **Pipeline Stages** — inter-stage communication in processors

### FIFO vs LIFO (Stack)
- **FIFO:** First in, first out (queue)
- **LIFO:** Last in, first out (stack)

---

## Key Concepts

### 1. Full & Empty Flags

#### Why Can't We Use `wr_ptr == rd_ptr`?

**The Pointer Comparison Problem:**

After wrapping, pointers can be equal in **two different states**:
- **Empty:** wr_ptr == rd_ptr, count == 0 (no data)
- **Full:** wr_ptr == rd_ptr, count == DEPTH (all slots filled)

**Solution:** Use a **count register** to disambiguate.

**Example:**
```
DEPTH = 8
- Initial (empty):  wr_ptr=0, rd_ptr=0, count=0
- After 8 writes:   wr_ptr=0, rd_ptr=0, count=8 (full!)
```

Both have `wr_ptr==rd_ptr`, but count tells us the truth.

### 2. Count-Based Detection

#### Empty
```systemverilog
assign empty = (count == 0);
```
- When count reaches 0, no valid data remains
- Prevents undefined reads

#### Full
```systemverilog
assign full = (count == DEPTH);
```
- When count reaches DEPTH, all slots are occupied
- Prevents data loss by blocking writes

---

### 3. Pointer Wraparound

After writing to or reading from the last location (DEPTH-1), pointers wrap to 0:

```
Write Pointer Sequence (DEPTH=8):
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 0 → 1 → ...
                                  └─ wraps!
```

**Implementation:**
```systemverilog
next_wr_ptr = (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1;
```

**Why?** Creates a circular buffer, reusing locations after they're emptied.

---

### 4. Simultaneous Read + Write

This is **critical** for maintaining throughput!

#### The Problem
If only one operation per cycle, throughput = 1 item/cycle at best.

#### The Solution
Allow **both read and write in the same cycle**:
- Write adds 1 item: count++
- Read removes 1 item: count--
- Net: count unchanged

**In code:**
```systemverilog
2'b11: begin
    // Both read and write enabled
    next_rd_ptr = rd_ptr + 1;  // Read pointer advances
    next_wr_ptr = wr_ptr + 1;  // Write pointer advances
    next_count  = count;        // Count unchanged!
end
```

**Use Case:** Streaming data through the FIFO while also filling it.

---

## Corner Cases & Solutions

### Corner Case 1: Read When Empty

**What Happens:**
- `empty == 1` (no valid data)
- `dout` shows stale data (previous read value)
- `rd_ptr` doesn't advance
- **No data is lost** (there was nothing to read)

**Application Must:**
- Check `empty` flag before using `dout`
- Only trust `dout` when `empty == 0`

### Corner Case 2: Write When Full

**What Happens:**
- `full == 1` (no room)
- Write is **silently dropped** (not executed)
- Data is **lost** if application doesn't notice
- `count` unchanged

**Application Must:**
- Check `full` flag before writing
- Implement backpressure or flow control
- Retry write if necessary

### Corner Case 3: Write While Draining

**Scenario:** FIFO has 1 item, simultaneous read+write
```
Before: count = 1
Read: count--  (removes 1)
Write: count++ (adds 1)
After: count = 1 (unchanged)
```
**Result:** FIFO stays at 1 item (pass-through mode)

---

## Design Decisions

### Decision 1: Count vs. Extra Pointer Bit

**Option A: Count Register** (our approach)
- ✅ Simple logic (`empty = count==0`, `full = count==DEPTH`)
- ✅ Easy to understand
- ✅ Slightly more area (one extra bit per count value)

**Option B: Extra Pointer Bit**
- ✅ No separate count register
- ❌ Complex comparison logic
- ❌ Harder to derive full/empty from pointer bits alone

**Decision:** Use count (simpler, clearer).

### Decision 2: Blocking Write vs. Error Signaling

**Option A: Blocking Write** (our approach)
- Write silently ignored if full
- Application must check `full` before writing
- Simpler logic, less wiring

**Option B: Error/Overflow Signals**
- Extra signal for write overflow
- Application is notified of dropped writes
- More complex, more signals

**Decision:** Use blocking (simpler for basic FIFO).

### Decision 3: Combinational vs. Registered Read

**Our Approach: Combinational Read**
- `dout = mem[rd_ptr]` (immediate, no pipeline delay)
- Address → memory data in same cycle
- ✅ Low latency
- ❌ Can increase critical path

**Alternative: Registered Read**
- `dout` latched after clock edge
- ✅ Longer cycle time available
- ❌ One cycle latency on reads

**Decision:** Combinational (throughput-friendly).

---

## Potential Issues & Fixes

### Issue 1: Integer Overflow on Count

**Problem:**
```systemverilog
count <= count + 1;  // If count is 8 bits, 255+1 = 0
```

**Fix:**
```systemverilog
parameter DEPTH = 256;
localparam ADDR_WIDTH = 8;  // log2(256)
logic [ADDR_WIDTH:0] count;  // 9 bits! (0-256)
```
Use `ADDR_WIDTH+1` bits for count.

### Issue 2: Pointer Width

**Problem:**
```systemverilog
logic [2:0] rd_ptr;  // For DEPTH=8, range 0-7 (3 bits enough)
```

**Fix:**
```systemverilog
localparam ADDR_WIDTH = $clog2(DEPTH);
logic [ADDR_WIDTH-1:0] rd_ptr;  // Automatically sized
```

### Issue 3: Read Pointer Wraparound

**Problem:**
```systemverilog
next_rd_ptr = rd_ptr + 1;  // Doesn't wrap!
```

**Fix:**
```systemverilog
next_rd_ptr = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
```

---

## Testing Strategy

### Phase 1: Reset
- Verify FIFO is empty after reset
- Verify flags: `empty=1, full=0, count=0`

### Phase 2: Fill
- Write to capacity
- Verify `full=1` after DEPTH writes

### Phase 3: Overflow
- Attempt write when full
- Verify write is blocked (count unchanged)

### Phase 4: Drain
- Read all entries
- Verify FIFO order (FIFO property)
- Verify `empty=1` after DEPTH reads

### Phase 5: Underflow
- Attempt read when empty
- Verify read is blocked (count unchanged)

### Phase 6: Simultaneous R/W
- Partial fill, then R/W simultaneously
- Verify count stays constant

---

## Expected Behavior Summary

| Scenario | wr_en | rd_en | full | empty | Action | count Change |
|----------|-------|-------|------|-------|--------|--------------|
| Write | 1 | 0 | 0 | x | Write ✓ | +1 |
| Write | 1 | 0 | 1 | x | Blocked ✗ | 0 |
| Read | 0 | 1 | x | 0 | Read ✓ | -1 |
| Read | 0 | 1 | x | 1 | Blocked ✗ | 0 |
| Both | 1 | 1 | 0 | 0 | Both ✓ | 0 |
| Idle | 0 | 0 | x | x | None | 0 |

