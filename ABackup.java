public class A {
    public static void main(String... main) {
        System.out.println("foobar");
    }

    public void b() {
        ;
    }

    public void b'() {
        a;
        b;
        c;
    }

    public void c() {
        System.out.println("abcd");
        Span span = new DefaultSpanBuilder(a);
        try (Scope s = Tracing.activateSpan(span)) {
            System.out.println("efgh");
        } finally {
            span.finish();
        }
    }

    public void d() {
        System.out.println("abcd");
        Span span = new DefaultSpanBuilder(a)
                    .tag(b)
                    .tag(c);
        try (Scope s = Tracing.activateSpan(span)) {
            System.out.println("efgh");
        } finally {
            span.finish();
        }
    }

    public void e() {
        System.out.println("abcd");
        Span span = new DefaultSpanBuilder(a);
        try (Scope s = Tracing.activateSpan(span)) {
            System.out.println("efgh");
        } finally {
            anotherStatement;
            span.finish();
            andAnotherStatement;
        }
    }
    
    public void f() {
        System.out.println("abcd");
        Span span = new DefaultSpanBuilder(a);
        try (String b = new String("asdf"); Scope s = Tracing.activateSpan(span) ; String c = new String("ghjk")) {
            System.out.println("efgh");
        } finally {
            span.finish();
        }
    }
}
