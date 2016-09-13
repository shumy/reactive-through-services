package rt.vertx.server.intercept

import org.eclipse.xtend.lib.annotations.Accessors
import io.vertx.core.Vertx

class KeycloakJwtProvider implements JwtProvider {
	@Accessors val issuer = 'http://localhost:8081/auth/realms/dev'
	@Accessors val String audience
	
	new(Vertx vertx, String audience) {
		this.audience = audience
	}
	
	override getPubKey(String kid) {
		return '-----BEGIN CERTIFICATE-----MIIClTCCAX0CBgFXHfu7eDANBgkqhkiG9w0BAQsFADAOMQwwCgYDVQQDDANkZXYwHhcNMTYwOTEyMTAzODM5WhcNMjYwOTEyMTA0MDE5WjAOMQwwCgYDVQQDDANkZXYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD19dSJHLTnqzBI2Rywtg39S5fSFbiJ//UNfhDWCzd2z9dYC+BCNkMt7P0+nHT55s5+QkXLDl+PTZf21QAITudzK8IyHdWeJI96gYWEYAw7U5tkoyf1/I1v6r3e1wyKc5cGIrlQ08qC9M5ZwUurwYnSTvnzYiUxBT52Ty73ZVPnMc8yQneXeX/Rr+pvueBv37EVSjbNMXWAD2ZCYt9gDs/HhKGvzzIze4GZCXkjAoXeZjpoEBLVN/65lUGWgYPBAgn7AhSa78+Jt14Yb564k/CnFeg6fCkRQCf1luYQQ6dMAsVLNMIHco5mwX8mpPiUAg/HjShZyjfC1ja2iKo81hELAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAObTBo/7vXV8QQk63LHPif4SXKshSBISot3zMNoiVDcQc2uswYBGZ3N7cgol3YLsA+AGzD+xwY5Lr74UBzCR4MgdCmhFJNeakNP9Z4O4y2VZfP3wtXvvyysOiZPjf8JGXKIDMfKNbRpazPvHPgkq1I8ciUdiA+zdXASC9haVlTC0QzyukpdojlBiNmq4VBPkq+WJ1YA+aIiFemh+XNiki9q6GbRKZAlvWIo9U1ZqK/wGWP/6mUhIJ6CJ9sXBVtaw+BjfTSw5Rw309XpXmh/jql24fSNZVbh7t3KpZJItMP97detWQ/R5PVGnlcD21N9rU5egu1Oc5Cu7l90pNbQmAUk=-----END CERTIFICATE-----'
	}
}