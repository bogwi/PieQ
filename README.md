# PieQ, A PriorityQueue ADT in ZIG

## Foreword

How fast is PieQ? On Apple M1 CPU, inserting in random order and popping out 100 000 000 unsigned 32-bit integers pairs in ReleaseFast mode takes `1.5` sec for insert and around `20` seconds for remove. Cumulative time stayed within `22` seconds for many tries, which somewhat pushes PieQ into HashMap territory. And PieQ does not warp under heavy load because there are no recursive calls. Add+remove time compared to ZIG's standard library PriorityQueue gives that PieQ is twice as fast.

The API is designed to be as literal and self-explanatory as possible. PieQ uses an implicit data structure, so there is no memory allocation routine here. The possible error's surface is reduced to a bare minimum, like warning you when the Queue is empty but you still want to pop something out of it; that has to be an error. Every public method, where needed, has a comprehensive doc string, and the full API is used in the testing section. Interesting uncommon features like changing the root or locking the root were implemented as well.

PieQ has two operational mods, min-oriented and max-oriented, turned on when passing `.min` or `.max` parameters during initiation. This is the general idea of Priority Queue. However, keys can be complex types as well, so the idea of min or max Queue is rather scratching the surface. PieQ gives you an option to define what is min and what is max as well. PieQ is designed to handle any key, not only real numbers but anything you know how to compare; if not, invent how. Say, PieQ can be used as a data filter, sorting multi-valued Items together, like enum's literals, for example. Or, you can filter Items with particular keys of your interest and put them strictly in front of the Queue to pop them earlier than the rest. Perhaps you wished to put vectors as keys in Queue; or functions, calling other functions, you can do it.

Potential usage cases might be many dozens, I can't mention all, but anyway, the testing section is a good place to start.
Possible applications that comes to mind are Heavy load balancers, Stock Market or Big Finance related tasks-schedulers, large-scale medical solutions, graphs, for Dijkstra, of course, statistics, and anywhere where you need scheduled event processing.

## Benchmark
If you are interested in how well PieQ runs on your system, try `bench` step. Run this:
```zig
zig build bench -- 12345678
```
and you will get stats for your machine

```
PieQ:        12_345_678 items
|action  |push    |pop     |sum     |
|time:sec|0.1563  |2.0006  |2.1569  |
|ns:item |12.6578 |162.0510|174.7088|
```

Running `zig build bench` without arguments tests on default 1Mil. With modern CPUs, it makes sense to test it harder, above 10Mils at least. Or if you know beforehand the size of data you intend to run, it is great to make such a test; or against other Priority Queue implementations to find the best option for your code.


## Usage

1. Add `PieQ` as a dependency in your `build.zig.zon`.

    <!-- <details> -->

    <!-- <summary><code>build.zig.zon</code> example </summary> -->

    ```zig
    .{
        .name = "name_of_your_package",
        .version = "version_of_your_package",
        .dependencies = .{
            .PieQ = .{
                .url = "https://github.com/bogwi/PieQ/archive/master.tar.gz",
                .hash = "1220dbe03c05ad89578e9522d3f2ff1fa611495f770773c711979ac00e48fd2825e9",
            },
        },
    }
    ```
    If the hash has changed, you will get a gentle  `error: hash mismatch` where in the field `found:` ZIG brings you the correct value.

    <!-- </details> -->

2. Add `PieQ` as a module in your `build.zig`.

    <!-- <details> -->

    <!-- <summary><code>build.zig</code> example </summary> -->

    ```zig
    const pieQ = b.dependency("PieQ", .{});
    exe.addModule("PieQ", pieQ.module("PieQ"));
    ```
    Using the module in test scopes, requires one more declaration with the same constant (if you need the module in tests, of course).
    ```zig
    unit_tests.addModule("PieQ", pieQ.module("PieQ"));

    ``` 

    <!-- </details> -->

3. Import the module.
    ```zig
        const PriorityQueue = @import("PieQ").PieQ;
    ```
4. This is your comparison function if you want numbers.
    ```zig
        fn compareU32(isMin: bool, a: u32, b: u32) bool {
            while (isMin)
                return a <= b;
            return a >= b;
        }
    ```
5. And this this how you initiate the Queue.
    ```zig
        var minQueue = PriorityQueue(u32, u32, .min, compareU32).init(your_allocator);
        defer minQueue.deinit();
    ```

To find more, please look at the testing section, file `pie_queue.zig`. Tests and the code are placed together so you can explore the implementation better, hovering over the functions and all. Thanks.
