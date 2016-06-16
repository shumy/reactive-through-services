package rt.plugin.output;

import org.eclipse.aether.impl.DefaultServiceLocator;

public class DefaultErrorHandler extends DefaultServiceLocator.ErrorHandler {
	@Override
	public void serviceCreationFailed(Class<?> type, Class<?> impl, Throwable exception) {
		exception.printStackTrace();
	}
}
