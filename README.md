# Priority Queue in ZIG

## Foreword

How fast is PieQ? On the Apple M1 CPU, inserting in random order and removing 100,000,000 unsigned 32-bit integer pairs in ReleaseFast mode takes `1.5` seconds for insert and about `20` seconds for remove. The cumulative time stayed within `22` seconds for many attempts, which pushes PieQ a bit into HashMap territory. And PieQ does not warp under heavy load because there are no recursive calls. Add+remove time compared to ZIG's standard PriorityQueue library shows that PieQ is twice as fast.

The API is designed to be as literal and self-explanatory as possible. PieQ uses an implicit data structure, so there is no memory allocation routine. The possible error interface is reduced to a bare minimum, like warning you if the queue is empty and you still want to pull something from it; that must be an error. Every public method has a comprehensive doc string where needed, and the full API is used in the test section. Interesting uncommon features like changing the root or locking the root are also implemented.

PieQ has two modes of operation, min-oriented and max-oriented, which are turned on by passing `.min' or `.max' parameters during initiation. This is the general idea of a priority queue. However, keys can also be complex types, so the idea of a min or max queue only scratches the surface. PieQ gives you the ability to define what is min and what is max as well. PieQ is designed to handle any key, not just real numbers, but anything you know how to compare; if not, invent how. For example, PieQ can be used as a data filter, sorting multi-valued elements together, such as enum's literals. Or you can filter items with certain keys you are interested in and put them strictly in front of the queue to pop them earlier than the rest. Maybe you want to queue vectors as keys, or functions that call other functions, you can do that.

There could be many dozens of possible use cases, I can't mention them all, but the testing section is a good place to start.
Applications that come to mind are heavy load balancers, stock market or large financial tasks - schedulers, medical solutions; then graphs, Dijkstra, of course, statistics, and anywhere you need scheduled event processing.

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

Running `zig build bench` without arguments tests on the default 1Mil. With modern CPUs, it makes sense to test harder, at least above 10Mils. Or if you know in advance the amount of data you intend to run, it is great to do such a test; or against other priority queue implementations to find the best option for your code.


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
                .url = "https://github.com/bogwi/pieQ/archive/master.tar.gz",
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
        const PieQ = @import("PieQ").PieQ;
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
        var minQueue = PieQ(u32, u32, .min, compareU32).init(your_allocator);
        defer minQueue.deinit();
    ```

To find out more, see the testing section, file `pieq.zig`. Tests and code are placed together so you can explore the implementation better, hovering over the functions and all. Thanks.
