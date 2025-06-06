export interface LiveActivityPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
