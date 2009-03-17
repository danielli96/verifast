public class Counter {

  int value;

  Counter(int v)
    //@ requires emp;
    //@ ensures result.value |-> v;
  {
    this.value=v;
  }
  Counter(Counter v)
    //@ requires v.value |-> ?t;
    //@ ensures v.value |-> t &*& result.value |-> t;
  {
    this.value=v.value;
  }
  Counter(int v,int b)
    //@ requires emp;
    //@ ensures result.value |-> v+b;
  {
    this.value=v+b;
  }
    
  void increment()
    //@ requires this.value |-> ?v;
    //@ ensures this.value |-> v + 1;
  {
    this.value = this.value + 1;
  }

  static void swap(Counter c1, Counter c2)
    //@ requires c1.value |-> ?v1 &*& c2.value |-> ?v2;
    //@ ensures c1.value |-> v2 &*& c2.value |-> v1;
  {
    int tmp = c1.value;
    c1.value = c2.value;
    c2.value = tmp;
  }

  public static void main(String[] args)
    //@ requires true;
    //@ ensures true;
  {
    Counter c1 = new Counter(0);
    Counter c2 = new Counter(5);
    Counter c3 = new Counter(5,5);
    Counter c4= new Counter(c2);
    c1.increment();
    Counter.swap(c1, c2);
    int tmp = c2.value;
    //@ assert tmp == 1;
    tmp=c3.value;
    //@ assert tmp==10;
    tmp=c4.value;
    int tmp2=c1.value;
    //@ assert tmp==tmp2;
  }
}
