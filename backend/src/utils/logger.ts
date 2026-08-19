import { sanitizeObject, sanitizeString } from './sanitizer.utils';

export interface LogContext {
  requestId?: string;
  method?: string;
  path?: string;
  statusCode?: number;
  [key: string]: any;
}

export class Logger {
  private static formatMessage(level: string, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString();
    const reqIdStr = context?.requestId ? ` [req:${context.requestId}]` : '';
    const safeContext = context ? sanitizeObject(context) : undefined;
    const contextStr = safeContext && Object.keys(safeContext).length > 0 ? ` ${JSON.stringify(safeContext)}` : '';
    return `[${timestamp}] [${level}]${reqIdStr} ${sanitizeString(message)}${contextStr}`;
  }

  public static info(message: string, context?: LogContext): void {
    console.log(Logger.formatMessage('INFO', message, context));
  }

  public static warn(message: string, context?: LogContext): void {
    console.warn(Logger.formatMessage('WARN', message, context));
  }

  public static error(message: string, context?: LogContext): void {
    console.error(Logger.formatMessage('ERROR', message, context));
  }

  public static debug(message: string, context?: LogContext): void {
    if (process.env.NODE_ENV === 'development') {
      console.debug(Logger.formatMessage('DEBUG', message, context));
    }
  }
}
