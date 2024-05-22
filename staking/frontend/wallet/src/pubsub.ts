export class PubSub<T> {

  private handlers: { [key: string]: any[] } = {};

  public subscribe<E extends keyof T & string>(
    event: E,
    callback: (message: T[E]) => void,
  ) {
    const list = this.handlers[event] ?? [];
    list.push(callback);
    this.handlers[event] = list;

    return callback;
  };

  public unsubscribe<E extends keyof T & string>(
      event: E,
      callback: (message: T[E]) => void,
  ) {
    let list = this.handlers[event] ?? [];
    list = list.filter(h => h !== callback);
    this.handlers[event] = list;
  };

  public publish<E extends keyof T & string>(
    event: E,
    message: T[E],
  ) {
    this.handlers[event]?.forEach(h => h(message));
  };
}
